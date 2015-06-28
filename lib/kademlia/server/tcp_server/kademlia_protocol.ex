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
    PB.PBNode,
    PB.PBHeader,
    PB.PBPingRequest,
    PB.PBFindNodeRequest,
    PB.PBFindValueRequest,
    PB.PBStoreValueRequest
  ]

  @default_closes_node_count 10


  @doc """
  Start receiving from the `socket` and responding to messages accordingly
  """
  def start_link(ref, socket, transport, opts) do
    Logger.debug "Started"
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
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
        handle_message_and_send_response(socket, transport, opts, data)
        server_loop(socket, transport, opts)
      x ->
        Logger.debug x
        :ok = transport.close(socket)
    end
  end

  @doc """
  Handles the message and then sends back the response
  """
  defp handle_message_and_send_response(socket, transport, opts, msg) do
    resp = handle_message(msg, opts[:node], opts[:network_id])
    encoded_resp = PBUtil.encode(resp)
    transport.send(socket, encoded_resp)
  end

  # Message handling code

  @doc """
  Handle the binary message, decode it and process it.
  """
  @spec handle_message(binary, Node.t, String.t) :: any
  defp handle_message(msg, node, network_id) when is_binary(msg) do
    case decode_pb_request(msg) do
      :error ->
        nil
      decoded_message ->
        handle_message(decoded_message, node, network_id)
    end
  end

  @spec handle_message(Contract.PingRequest.t, Node.t, String.t) :: Contract.PingResponse.t
  defp handle_message(%Contract.PingRequest{header: header}, node, network_id) do
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
    case KVStoreAgent.get(key) do
      {:ok, value} ->
        %Contract.FindValueResponse{
          header: create_header(node, network_id),
          value: value
        }

      {:error, :not_found} ->
        %Contract.FindValueResponse{
          header: create_header(node, network_id),
          nodes: RoutingTableAgent.find_closest_node(key, @default_closes_node_count)
        }
    end
  end

  @spec handle_message(Contract.StoreValueRequest.t, Node.t, String.t) :: Contract.StoreValueResponse.t
  defp handle_message(%Contract.StoreValueRequest{header: _header, key: key, value: value}, node, network_id) do
    case KVStoreAgent.put(key, value) do
      :ok ->
        %Contract.StoreValueResponse{header: create_header(node, network_id), status: 0}
      _ ->
        %Contract.StoreValueResponse{header: create_header(node, network_id), status: 2}
    end
  end

  @spec decode_pb_request(binary) :: %{} | :error
  defp decode_pb_request(bin) when is_binary(bin) do
    decode_pb_request(bin, @request_pb_modules)
  end

  @spec decode_pb_request(binary, [any]) :: %{} | :error
  defp decode_pb_request(bin, [h|t]) when is_binary(bin) do
    try do
      h.decode(bin) |> PBUtil.decode
    rescue
      _e -> decode_pb_request(bin, t)
    end
  end

  defp decode_pb_request(bin, []) when is_binary(bin), do: :error

  @doc """
  Create the header for this node
  """
  @spec create_header(Node.t, String.t) :: Contract.Header.t
  defp create_header(sender, network_id) do
    %Contract.Header{sender: sender, network_id: network_id, message_id: Node.create_rand_id}
  end

end
