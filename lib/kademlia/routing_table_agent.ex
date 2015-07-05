defmodule Kademlia.RoutingTableAgent do

  alias Kademlia.RoutingTable, as: RoutingTable
  alias Kademlia.Node, as: Node

  @doc """
  Start the agent for the routing table
  """
  @spec start_link(Node.t) :: {:ok, pid} | {:error, any}
  def start_link(node) do
    Agent.start_link(fn -> RoutingTable.new(node) end, name: __MODULE__)
  end

  @doc """
  Get routing table
  """
  @spec get() :: RoutingTable.t
  def get() do
    Agent.get __MODULE__, &(&1)
  end

  @doc """
  Update the routing table with `node`
  """
  @spec update(Node.t) :: :ok
  def update(node) do
    Agent.update __MODULE__, fn(rtable) ->
      RoutingTable.update(rtable, node)
    end
  end

  @doc """
  Find `count` closest nodes to `node`
  """
  @spec find_closest_node(Node.t, pos_integer) :: RoutingTable.closest_nodes_list
  def find_closest_node(node, count) do
    Agent.get __MODULE__, fn(rtable) ->
      RoutingTable.find_closest_node(rtable, node, count)
    end
  end

  @doc """
  Find the `count` closes nodes to `key`
  """
  @spec find_closest(Node.node_id, pos_integer) :: RoutingTable.closest_nodes_list
  def find_closest(key, count) do
    Agent.get __MODULE__, fn(rtable) ->
      RoutingTable.find_closest(rtable, key, count)
    end
  end

end
