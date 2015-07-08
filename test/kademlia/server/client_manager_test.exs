defmodule Kademlia.Server.ClientManagerTest do
  use ExUnit.Case

  require Logger
  alias Kademlia.Node
  alias Kademlia.RoutingTableAgent
  alias Kademlia.Server.TcpServer
  alias Kademlia.Server
  alias Kademlia.Store.KVStoreAgent
  alias Kademlia.Server.ClientManager

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

    Logger.debug "Starting client manager"
    ClientManager.start_link(node, network_id)

    Logger.debug "Done initializing"
    {:ok, node: node, network_id: network_id, target_node: target_node}
  end

  test "sending Ping to server and getting Pong from the server", %{node: node, network_id: network_id, target_node: target_node} do

    resp = ClientManager.ping(target_node) |> ClientManager.await

    Logger.debug "Response for ping: #{inspect(resp)}"
    assert resp != nil
  end

  test "sending store value to server and then retrieving the value", %{node: node, network_id: network_id, target_node: target_node} do
    key = "test_key"
    value = << 1,2,3,4,5 >>

    resp = ClientManager.store_value(target_node, key, value) |> ClientManager.await
    Logger.debug "Response for store_value: #{inspect(resp)}"

    assert {:ok, _} = resp

    Logger.debug "KVStore has key: #{KVStoreAgent.has_key?(key)}"

    resp = ClientManager.find_value(target_node, key) |> ClientManager.await
    Logger.debug "Response for find_value: #{inspect(resp)}"
    assert {:ok, _} = resp

    {:ok, %Server.Contract.FindValueResponse{value: value_found}}= resp

    assert value_found == value
  end
end
