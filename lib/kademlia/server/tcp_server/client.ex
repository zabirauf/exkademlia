defmodule Kademlia.Server.TcpServer.Client do
  @moduledoc """
  The clinet to connect to a node over TCP socket
  """

  @behaviour Kademlia.Server.Client

  use GenServer

  require Logger

  import Kademlia.Node
  alias Kademlia.Server.TcpServer.Protobuf.ProtobufUtil, as: PBUtil
  alias Kademlia.Server.TcpServer.Protobuf, as: PB
  alias Kademlia.Server.Contract, as: Contract

  @default_timeout 6000

  # This should be in sync with the inverted map in TcpServer.KademliaProtocol
  @request_module_to_prefix_map %{
    "Elixir.Kademlia.Server.TcpServer.Protobuf.PBPingRequest":       <<10>>,
    "Elixir.Kademlia.Server.TcpServer.Protobuf.PBFindNodeRequest":   <<20>>,
    "Elixir.Kademlia.Server.TcpServer.Protobuf.PBFindValueRequest":  <<30>>,
    "Elixir.Kademlia.Server.TcpServer.Protobuf.PBStoreValueRequest": <<40>>,
  }

  # The helper functions to be called

  @doc "Start"
  def start_link(node, sender, network_id, opts) do
    GenServer.start_link(__MODULE__, {node, sender, network_id, opts})
  end

  @doc "Ping the node"
  def ping(client) do
    GenServer.call(client, :ping, :infinity)
  end

  @doc "Find a node in the network. The response should never include the node being contacted"
  def find_node(client, target) do
    GenServer.call(client, {:find_node, target}, :infinity)
  end

  @doc "Find a value in the network"
  def find_value(client, key) do
    GenServer.call(client, {:find_value, key}, :infinity)
  end

  @doc "Store a value in the network"
  def store_value(client, key, value) do
    result = GenServer.call(client, {:store_value, key, value})
    Logger.debug "Kademlia.Server.TcpServer.Client.store_value/3: Result is #{inspect(result)}"
    result
  end

  # Gen server callbacks

  @doc "Connect the client with the `node`"
  def init({node, sender, network_id, opts}) do
    socket = Socket.TCP.connect! node.endpoint, node.port, packet: :raw
    {:ok, {node, sender, network_id, socket, opts}}
  end

  @doc "Ping the node"
  @spec handle_call(:ping, pid, {Node.t, Node.t, String.t, any, [term]}) :: any
  def handle_call(:ping, _from, {_node, sender, network_id, socket, opts} = state) do
    %Contract.PingRequest{header: create_header(sender, network_id)}
    |> send_req_and_get_resp(socket, opts, state, PB.PBPingResponse, PB.PBPingRequest)
  end

  @doc "Find the node"
  @spec handle_call({:find_node, Node.t}, pid, {Node.t, Node.t, String.t, any, [term]}) :: any
  def handle_call({:find_node, target}, _from, {_node, sender, network_id, socket, opts} = state) do
    %Contract.FindNodeRequest{header: create_header(sender, network_id), target: target}
    |> send_req_and_get_resp(socket, opts, state, PB.PBFindNodeResponse, PB.PBFindNodeRequest)
  end

  @doc "Find the value at the node"
  @spec handle_call({:find_value, Node.node_id}, pid, {Node.t, Node.t, String.t, any, [term]}) :: any
  def handle_call({:find_value, key}, _from, {_node, sender, network_id, socket, opts} = state) do
    %Contract.FindValueRequest{header: create_header(sender, network_id), key: key}
    |> send_req_and_get_resp(socket, opts, state, PB.PBFindValueResponse, PB.PBFindValueRequest)
  end

  @doc "Store the value at the node"
  @spec handle_call({:store_value, Node.node_id, binary}, pid, {Node.t, Node.t, String.t, any, [term]}) :: any
  def handle_call({:store_value, key, value}, _from, {_node, sender, network_id, socket, opts} = state) do
    %Contract.StoreValueRequest{header: create_header(sender, network_id), key: key, value: value}
    |> send_req_and_get_resp(socket, opts, state, PB.PBStoreValueResponse, PB.PBStoreValueRequest)
  end

  @doc "Send a request to the node and get the response back"
  @spec send_req_and_get_resp(any, any, [term], any, atom, atom) :: any
  defp send_req_and_get_resp(req, socket, opts, state, decoding_module, encoding_module) do

    # Encode the request to binary and prepend with the request type prefix
    # Send the encoded request over the socket
    Logger.debug "TcpServer.Client.send_req_and_get_resp: Request #{inspect(req)}"

    # Prefixing the module prefix number so that at server side it knows the type of request
    prefix = Dict.get(@request_module_to_prefix_map, encoding_module)
    encoded =  prefix <> PBUtil.encode(req)

    Logger.debug "TcpServer.Client.send_req_and_get_resp: Encoded Request #{inspect(encoded)}"

    socket |> Socket.Stream.send!(encoded)

    # Wait for the response from the node and decoded the response
    socket
    |> Socket.Stream.recv(timeout: opts[:timeout] || @default_timeout)
    |> (fn(resp) ->
          Logger.debug "TcpServer.Client.send_req_and_get_resp: Encoded Response #{inspect(resp)}"
          resp
       end).()
    |> process_resp(decoding_module, state)
  end

  @doc "Create the request header"
  @spec create_header(Node.t, String.t) :: Contract.Header.t
  defp create_header(sender, network_id) do
    %Contract.Header{sender: sender, network_id: network_id, message_id: create_rand_id}
  end

  @doc "Process the `resp`onse by decoding it and if its nil then returning message to close the socket"
  defp process_resp(resp, decoding_module, state) do
    case resp do
      {:error, error} ->
        {:reply, {:error, error}, state}
      {:ok, :nil} ->
        {:stop, :sock_closed, {:error, :closed}, state}
      {:ok, d} ->
        decoded_response = d |> decoding_module.decode |> PBUtil.decode
        {:reply, {:ok, decoded_response}, state}
    end
  end
end
