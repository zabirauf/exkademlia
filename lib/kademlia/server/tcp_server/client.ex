defmodule Kademlia.Server.TcpServer.Client do
  @behaviour Kademlia.Server.Client

  use GenServer

  import Kademlia.Node
  alias Kademlia.Server.TcpServer.Protobuf.ProtobufUtil, as: PBUtil
  alias Kademlia.Server.TcpServer.Protobuf, as: PB
  alias Kademlia.Server.Contract, as: Contract

  @default_timeout 6000

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
    GenServer.call(client, {:store_valye, key, value}, :infinity)
  end

  # Gen server callbacks

  def init({node, sender, network_id, opts}) do
    socket = Socket.connect! node.endpoint, node.port, packet: :line
    {:ok, {node, sender, network_id, socket, opts}}
  end

  def handle_call(:ping, _from, {_node, sender, network_id, socket, opts} = state) do
    %Contract.PingRequest{header: create_header(sender, network_id)}
    |> send_req_and_get_resp(socket, opts, state, PB.PBPingResponse)
  end

  def handle_call({:find_node, target}, _from, {_node, sender, network_id, socket, opts} = state) do
    %Contract.FindNodeRequest{header: create_header(sender, network_id), target: target}
    |> send_req_and_get_resp(socket, opts, state, PB.PBFindNodeResponse)
  end

  def handle_call({:find_value, key}, _from, {_node, sender, network_id, socket, opts} = state) do
    %Contract.FindValueRequest{header: create_header(sender, network_id), key: key}
    |> send_req_and_get_resp(socket, opts, state, PB.PBFindValueResponse)
  end

  def handle_call({:store_value, key, value}, _from, {_node, sender, network_id, socket, opts} = state) do
    %Contract.StoreValueRequest{header: create_header(sender, network_id), key: key, value: value}
    |> send_req_and_get_resp(socket, opts, state, PB.PBStoreValueResponse)
  end

  defp send_req_and_get_resp(req, socket, opts, state, decoding_module) do
    encoded = PBUtil.encode(req)
    socket |> Socket.Stream.send!(encoded)

    socket
    |> Socket.Stream.recv(timeout: opts[:timeout] || @default_timeout)
    |> process_resp(decoding_module, state)
  end

  defp create_header(sender, network_id) do
    %Contract.Header{sender: sender, network_id: network_id, message_id: create_rand_id}
  end

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
