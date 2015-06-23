defmodule Kademlia.RoutingTableTest do
  use ExUnit.Case

  require Logger
  alias Kademlia.Node, as: Node
  alias Kademlia.RoutingTable, as: RoutingTable

  setup do
    {:ok, routing_table: RoutingTable.new(Node.new)}
  end

  test "find closest node", %{routing_table: rtable} do

    rtable = Enum.reduce 1..40, rtable, fn(_x, acc) ->
      RoutingTable.update(acc, Node.new)
    end

    closest_nodes = RoutingTable.find_closest_node(rtable, Node.new, 10)

    assert length(closest_nodes) == 10
  end
end
