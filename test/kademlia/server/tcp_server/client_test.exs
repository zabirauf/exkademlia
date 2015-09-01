defmodule Kademlia.Server.TcpServer.ClientTest do
  use ExUnit.Case

  require Logger
  alias Kademlia.Node
  alias Kademlia.RoutingTableAgent
  alias Kademlia.Server.TcpServer
  alias Kademlia.Server
  alias Kademlia.Store.KVStoreAgent

  setup do
    node = Node.new
    network_id = "Test_Kad_Network"
    target_node = Node.new("127.0.0.1", 5555)

    Logger.debug "Starting routing table"
    RoutingTableAgent.start_link(node)

    Logger.debug "Starting Memory KVStore"
    KVStoreAgent.start_link(Kademlia.Store.KVStore.MemoryKVStore)

    Logger.debug "Starting TCP server using Ranch"
    Kademlia.Server.TcpServer.KademliaProtocol.start_link(target_node, network_id)

    Logger.debug "Starting TCP client"
    {:ok, client} = TcpServer.Client.start_link(target_node, node, network_id, [])

    Logger.debug "Done initializing"
    {:ok, node: node, network_id: network_id, target_node: target_node, client: client}
  end

  test "sending Ping to server and getting Pong from the server", %{node: node, network_id: network_id, target_node: target_node, client: client} do

    resp = TcpServer.Client.ping(client)

    Logger.debug "Response for ping: #{inspect(resp)}"
    assert resp != nil
  end

  test "sending store value to server and then retrieving the value", %{node: node, network_id: network_id, target_node: target_node, client: client} do
    key = "test_key"
    value = << 1,2,3,4,5 >>

    resp = TcpServer.Client.store_value(client, key, value)
    Logger.debug "Response for store_value: #{inspect(resp)}"
    assert {:ok, _} = resp

    Logger.debug "KVStore has key: #{KVStoreAgent.has_key?(key)}"

    resp = TcpServer.Client.find_value(client, key)
    Logger.debug "Response for find_value: #{inspect(resp)}"
    assert {:ok, _} = resp

    {:ok, %Server.Contract.FindValueResponse{value: value_found}}= resp

    assert value_found == value
  end
end
