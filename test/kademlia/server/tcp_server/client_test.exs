defmodule Kademlia.Server.TcpServer.ClientTest do
  use ExUnit.Case

  require Logger
  alias Kademlia.Node
  alias Kademlia.RoutingTableAgent
  alias Kademlia.Server.TcpServer
  alias Kademlia.Server
  alias Kademlia.Store.KVStoreAgent

  @client_id :test_client

  setup do
    node = Node.new
    network_id = "Test_Kad_Network"
    target_node = Node.new("127.0.0.1", 5555)

    Logger.debug "Starting routing table"
    RoutingTableAgent.start_link(node)

    Logger.debug "Starting Memory KVStore"
    KVStoreAgent.start_link(Kademlia.Store.KVStore.MemoryKVStore)

    Logger.debug "Starting TCP server using Ranch"
    ret = :ranch.start_listener(:tcp_echo, 10, :ranch_tcp, [{:port, target_node.port}], TcpServer.KademliaProtocol, [node: target_node, network_id: network_id])

    Logger.debug "Starting TCP client"
    TcpServer.Client.start_link(@client_id, target_node, node, network_id, [])

    Logger.debug "Done initializing"
    {:ok, node: node, network_id: network_id, target_node: target_node}
  end

  test "Test sending Ping to server and getting Pong from the server", %{node: node, network_id: network_id, target_node: target_node} do

    resp = TcpServer.Client.ping(@client_id)

    Logger.debug "Response for ping: #{inspect(resp)}"
    assert resp != nil
  end

  test "Test sending store value to server and then retrieving the value", %{node: node, network_id: network_id, target_node: target_node} do
    key = "test_key"
    value = << 1,2,3,4,5 >>

    resp = TcpServer.Client.store_value(@client_id, key, value)
    Logger.debug "Response for store_value: #{inspect(resp)}"
    assert {:ok, _} = resp

    Logger.debug "KVStore has key: #{KVStoreAgent.has_key?(key)}"

    resp = TcpServer.Client.find_value(@client_id, key)
    Logger.debug "Response for find_value: #{inspect(resp)}"
    assert {:ok, _} = resp

    {:ok, %Server.Contract.FindValueResponse{value: value_found}}= resp

    assert value_found == value
  end
end
