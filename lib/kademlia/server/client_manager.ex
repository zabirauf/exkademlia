defmodule Kademlia.Server.ClientManager do
  @moduledoc """
  The client manager, which handles all the clients for the nodes in the network
  """

  require Logger
  alias Kademlia.Node

  use GenServer

  @type state :: [node: Node.t, network_id: String.t, clients: HashDict.t]

  # TODO: Get from the configuration
  @client_module Kademlia.Server.TcpServer.Client

  @doc """
  Start the client manager
  """
  @spec start_link(Node.t, String.t) :: {:ok, pid} | {:error, any}
  def start_link(node, network_id) do
    GenServer.start_link(__MODULE__, {node, network_id}, [name: __MODULE__])
  end

  @doc "Ping the node"
  @spec ping(Node.t) :: Task.t
  def ping(node) do
    GenServer.call(__MODULE__, {:ping, node}, :infinity)
  end

  @doc "Find a node in the network. The response should never include the node being contacted"
  @spec find_node(Node.t, Node.node_id) :: Task.t
  def find_node(node, target) do
    GenServer.call(__MODULE__, {:find_node, node, target}, :infinity)
  end

  @doc "Find a value in the network"
  @spec find_value(Node.t, Node.node_id) :: Task.t
  def find_value(node, key) do
    GenServer.call(__MODULE__, {:find_value, node, key}, :infinity)
  end

  @doc "Store a value in the network"
  @spec store_value(Node.t, Node.node_id, binary) :: Task.t
  def store_value(node, key, value) do
    GenServer.call(__MODULE__, {:store_value, node, key, value}, :infinity)
  end

  @doc "Await for the result of the request"
  @spec await({:client_manager_task, pos_integer, Task.t}, pos_integer) :: term | :timed_out
  def await({:client_manager_task, rand, _task}, timeout \\ 5000) do
    receive do
      {:client_manager_task, ^rand, result} -> result
    after
      timeout -> :timed_out
    end
  end

  # Gen server callbacks

  def init({node, network_id}) do
    {:ok, [node: node, network_id: network_id, clients: %HashDict{}]}
  end

  def handle_call({:ping, target_node}, from, state) do
    {client, updated_state} = get_node_client(target_node, state)
    {:reply, create_async_task(client, :ping, [], from), updated_state}
  end

  def handle_call({:find_node, target_node, target}, from, state) do
    {client, updated_state} = get_node_client(target_node, state)
    {:reply, create_async_task(client, :find_node, [target], from), updated_state}
  end

  def handle_call({:find_value, target_node, key}, from, state) do
    {client, updated_state} = get_node_client(target_node, state)
    {:reply, create_async_task(client, :find_value, [key], from), updated_state}
  end

  def handle_call({:store_value, target_node, key, value}, from, state) do
    {client, updated_state} = get_node_client(target_node, state)
    {:reply, create_async_task(client, :store_value, [key, value], from), updated_state}
  end

  # Helper functions

  @spec create_async_task(pid, atom, [term], pid) :: Task.t
  defp create_async_task(client, fun, args, {pid, _ref}) do
    :random.seed(:os.timestamp)
    rand = :random.uniform(4096)
    task = Task.start(fn ->
      result = apply(@client_module, fun, [client|args])
      send pid, {:client_manager_task, rand, result}
    end)

    # Sending a rand number so that the process can filter the result for this specific request
    # otherwise it might process some other result. To decrease chances of collision increase the
    # range of the generating pseudo random number
    {:client_manager_task, rand, task}
  end

  @spec get_node_client(Node.t, state) :: {pid, state}
  defp get_node_client(target_node, [node: node, network_id: _network_id, clients: map] = state) do
    Dict.get(map, node.id, :not_found) |> get_node_client_and_updated_state(target_node, state)
  end

  @spec get_node_client_and_updated_state(:not_found, Node.t, state) :: {pid, state}
  defp get_node_client_and_updated_state(:not_found, target_node, [node: node, network_id: network_id, clients: map]) do
    # If the client is not found then create client and update the map
    {:ok, client} = create_client(target_node, node, network_id)

    Logger.debug "Kademlia.Server.ClientManager: Client created for #{inspect(target_node)}"
    map = Dict.put(map, node.id, client)
    {client, [node: node, network_id: network_id, clients: map]}
  end

  @spec get_node_client_and_updated_state(pid, Node.t, state) :: {pid, state}
  defp get_node_client_and_updated_state(client, target_node, state) do
    # If the client is not alive then create one else return it
    if Process.alive?(client) do
      {client, state}
    else
      get_node_client_and_updated_state(:not_found, target_node, state)
    end
  end

  @spec create_client(Node.t, Node.t, String.t) :: {:ok, any} | {:error, any}
  defp create_client(target_node, node, network_id) do
    @client_module.start_link(target_node, node, network_id, [])
  end

end
