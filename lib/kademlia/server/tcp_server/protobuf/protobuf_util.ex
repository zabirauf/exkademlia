defmodule Kademlia.Server.TcpServer.Protobuf.ProtobufUtil do
  @moduledoc """
  Utility functions to encode and decode between protobuf entities and local entities
  """
  alias Kademlia.Server.Contract, as: Contract
  alias Kademlia.Server.TcpServer.Protobuf, as: PB

  # Encoding functions

  def encode(%Contract.Header{sender: sender, network_id: network_id, message_id: message_id}) do
    PB.PBHeader.new(Sender: sender, NetworkId: network_id, MessageId: message_id)
  end

  def encode(%Kademlia.Node{id: id, port: port, endpoint: endpoint}) do
    PB.PBNode.new(Id: id, Port: port, Endpoint: endpoint)
  end

  def encode(%Contract.PingRequest{header: header}) do
    PB.PBPingRequest.new(Header: encode(header))
    |> PB.PBPingRequest.encode
  end

  def encode(%Contract.PingResponse{header: header}) do
    PB.PBPingResponse.new(Header: encode(header))
    |> PB.PBPingResponse.encode
  end

  def encode(%Contract.FindNodeRequest{header: header, target: target}) do
    PB.PBFindNodeRequest.new(Header: encode(header), Target: target)
    |> PB.PBFindNodeRequest.encode
  end

  def encode(%Contract.FindNodeResponse{header: header,nodes: nodes}) do
    PB.PBFindNodeResponse.new(Header: encode(header), Nodes: Enum.map(nodes, &encode/1))
    |> PB.PBFindNodeResponse.encode
  end

  def encode(%Contract.FindValueRequest{header: header, key: key}) do
    PB.PBFindValueRequest.new(Header: encode(header), Key: key)
    |> PB.PBFindValueRequest.encode
  end

  def encode(%Contract.FindValueResponse{header: header, value: value, nodes: nodes}) do
    PB.PBFindValueResponse.new(Header: encode(header), Value: value, Nodes: Enum.map(nodes, &encode/1))
    |> PB.PBFindValueResponse.encode
  end

  def encode(%Contract.StoreValueRequest{header: header, key: key, value: value}) do
    PB.PBStoreValueRequest.new(Header: encode(header), Key: key, Value: value)
    |> PB.PBStoreValueRequest.encode
  end

  def encode(%Contract.StoreValueResponse{header: header, status: status}) do
    PB.PBStoreValueResponse.new(Header: encode(header), Status: status)
    |> PB.PBStoreValueResponse.encode
  end

  # Decoding functions

  def decode(%PB.PBHeader{Sender: sender, NetworkId: network_id, MessageId: message_id}) do
    %Contract.Header{sender: sender, network_id: network_id, message_id: message_id}
  end

  def decode(%PB.PBNode{Id: id, Port: port, Endpoint: endpoint}) do
    %Kademlia.Node{id: id, port: port, endpoint: endpoint}
  end

  def decode(%PB.PBPingRequest{Header: header}) do
    %Contract.PingRequest{header: decode(header)}
  end

  def decode(%PB.PBPingResponse{Header: header}) do
    %Contract.PingResponse{header: decode(header)}
  end

  def decode(%PB.PBFindNodeRequest{Header: header, Target: target}) do
    %Contract.FindNodeRequest{header: decode(header), target: target}
  end

  def decode(%PB.PBFindNodeResponse{Header: header, Nodes: nodes}) do
    %Contract.FindNodeResponse{header: decode(header), nodes: Enum.map(nodes, &decode/1)}
  end

  def decode(%PB.PBFindValueRequest{Header: header, Key: key}) do
    %Contract.FindValueRequest{header: decode(header), key: key}
  end

  def decode(%PB.PBFindValueResponse{Header: header, Value: value, Nodes: nodes}) do
    %Contract.FindValueResponse{header: decode(header), value: value, nodes: Enum.map(nodes, &decode/1)}
  end

  def decode(%PB.PBStoreValueRequest{Header: header, Key: key, Value: value}) do
    %Contract.StoreValueRequest{header: decode(header), key: key, value: value}
  end

  def decode(%PB.PBStoreValueResponse{Header: header, Status: status}) do
    %Contract.StoreValueResponse{header: decode(header), status: status}
  end

end
