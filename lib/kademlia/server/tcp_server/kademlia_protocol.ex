defmodule Kademlia.Server.TcpServer.KademliaProtocol do
  @moduledoc """
  The ranch protocol behavor implementation for kademlia protocol

  """
  @behaviour :ranch_protocol

  require Logger

  alias Kademlia.Server.TcpServer.Protobuf, as: PB
  alias Kademlia.Server.TcpServer.Protobuf.ProtobufUtil, as: PBUtil
  alias Kademlia.Server.Contract, as: Contract
  alias Kademlia.RoutingTableAgent, as: RoutingTableAgent
  alias Kademlia.Store.KVStoreAgent, as: KVStoreAgent
  alias Kademlia.Node, as: Node

  @request_pb_modules [
    PB.PBPingRequest,
    PB.PBFindNodeRequest,
    PB.PBFindValueRequest,
    PB.PBStoreValueRequest,
  ]

  # Should match the inverted of map in TcpServer.Client
  @request_prefix_to_module_map %{
    <<10>> => PB.PBPingRequest,
    <<20>> => PB.PBFindNodeRequest,
    <<30>> => PB.PBFindValueRequest,
    <<40>> => PB.PBStoreValueRequest,
  }

  @default_closes_node_count 10


  @doc """
  Start receiving from the `socket` and responding to messages accordingly
  """
  def start_link(ref, socket, transport, opts) do
    Logger.debug "Started"
    pid = spawn_link(__MODULE__, :listen, [ref, socket, transport, opts])
    {:ok, pid}
  end

  def listen(ref, socket, transport, opts) do
    Logger.debug "Connected"
    :ok = :ranch.accept_ack(ref)
    server_loop(socket, transport, opts)
  end

  @doc """
  Listens on socket for any message, decodeds it, process it and sends back the response and repeats the whole process again.
  """
  def server_loop(socket, transport, opts) do
    case transport.recv(socket, 0, -1) do
      {:ok, data} ->
        Logger.debug "KademliaProtocol TCP Server.server_loop: #{inspect(data)}"
        handle_message_and_send_response(socket, transport, opts, data)
        server_loop(socket, transport, opts)
      x ->
        Logger.debug "KademliaProtocol TCP Server.server_loop: #{inspect(x)}"
        :ok = transport.close(socket)
    end
  end

  @doc """
  Handles the message and then sends back the response
  """
  defp handle_message_and_send_response(socket, transport, opts, msg) do
    resp = handle_message(msg, opts[:node], opts[:network_id])
    Logger.debug "handle_message_and_send_response: #{inspect(resp)}"
    encoded_resp = PBUtil.encode(resp)

    Logger.debug "handle_message_and_send_response: #{inspect(encoded_resp)}"
    transport.send(socket, encoded_resp)
  end

  # Message handling code

  @doc """
  Handle the binary message, decode it and process it.
  """
  @spec handle_message(binary, Node.t, String.t) :: any
  defp handle_message(<<msg_type :: size(8), msg :: binary>>, node, network_id) when is_binary(msg) do
    decoding_module = Dict.get(@request_prefix_to_module_map, <<msg_type>>)
    Logger.debug "TcpServer.KademliaProtocol.handle_message/3: Decoding module is #{inspect(decoding_module)}, for key #{inspect(msg_type)} in #{inspect(@request_prefix_to_module_map)}"
    case decode_pb_request(decoding_module, msg) do
      :error ->
        nil
      decoded_message ->
        Logger.debug "Handle_message: binary: #{inspect(decoded_message)}"
        handle_message(decoded_message, node, network_id)
    end
  end

  @spec handle_message(Contract.PingRequest.t, Node.t, String.t) :: Contract.PingResponse.t
  defp handle_message(%Contract.PingRequest{header: header}, node, network_id) do
                                                                      Logger.debug "Handle PingRequest"
    {:ok, _pid} = Task.start fn ->
      RoutingTableAgent.update(header.sender)
    end

    %Contract.PingResponse{header: create_header(node, network_id)}
  end

  @spec handle_message(Contract.FindNodeRequest.t, Node.t, String.t) :: Contract.FindNodeResponse.t
  defp handle_message(%Contract.FindNodeRequest{header: _header, target: target}, node, network_id) do
    nodes = RoutingTableAgent.find_closest_node(target, @default_closes_node_count)
    %Contract.FindNodeResponse{header: create_header(node, network_id), nodes: nodes}
  end

  @spec handle_message(Contract.FindValueRequest.t, Node.t, String.t) :: Contract.FindValueResponse.t
  defp handle_message(%Contract.FindValueRequest{header: _header, key: key}, node, network_id) do

    Logger.debug "Handle FindValueRequest"

    case KVStoreAgent.get(key) do
      {:ok, value} ->
        %Contract.FindValueResponse{
          header: create_header(node, network_id),
          value: value
        }

      {:error, :not_found} ->
        # TODO: FIX: The find_closest_node second argument takes Node. See if we should change it to key?
        %Contract.FindValueResponse{
          header: create_header(node, network_id),
          nodes: RoutingTableAgent.find_closest(key, @default_closes_node_count)
        }
    end
  end

  @spec handle_message(Contract.StoreValueRequest.t, Node.t, String.t) :: Contract.StoreValueResponse.t
  defp handle_message(%Contract.StoreValueRequest{header: _header, key: key, value: value}, node, network_id) do

    Logger.debug "Handle StoreValueRequest"
    case KVStoreAgent.put(key, value) do
      :ok ->
        %Contract.StoreValueResponse{header: create_header(node, network_id), status: :STORED}
      _ ->
        %Contract.StoreValueResponse{header: create_header(node, network_id), status: :ERROR_GENERIC}
    end
  end

  @spec decode_pb_request(atom, binary) :: %{} | :error
  defp decode_pb_request(decoding_module, bin) when is_binary(bin) do
    try do
      Logger.debug "Decoding #{inspect(decoding_module)}"
      decoding_module.decode(bin) |> PBUtil.decode
    rescue
      e ->
        Logger.debug "Decoding error #{e}"
        :error
    end
  end

  @doc """
  Create the header for this node
  """
  @spec create_header(Node.t, String.t) :: Contract.Header.t
  defp create_header(sender, network_id) do
    %Contract.Header{sender: sender, network_id: network_id, message_id: Node.create_rand_id}
  end

end
