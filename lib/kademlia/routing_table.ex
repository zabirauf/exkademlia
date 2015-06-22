defmodule Kademlia.RoutingTable do

  alias Kademlia.RoutingTable, as: RoutingTable
  alias Kademlia.Node, as: Node
  alias Kademlia.Bucket, as: Bucket

  @type t :: %RoutingTable{node: Node.t, buckets: %{}}
  defstruct node: nil, buckets: %{}

  @k_buckets 160

  @doc """
  Creates a routing table with a map of buckets
  """
  @spec new(Node.t) :: RoutingTable.t
  def new(node) do
    table = %RoutingTable{node: node, buckets: %{}}

    # Initializing the table with the buckets
    Enum.reduce 0..@k_buckets-1, table, fn(x, acc) ->
      %{acc | buckets: Dict.put(acc.buckets, x, Bucket.new)}
    end
  end

  @doc """
  Updating the routing table with the Kademlia routing logic which is
    1. Move the node in the bucket to front if it exists
    2. If the node does not exists in the bucket then
       1. Add the node to the bucket if the bucket is not full
       2. If the bucket is full then try evicting the nodes that do not respond and then adding the node [TODO]
  """
  @spec update(RoutingTable.t, Node.t) :: RoutingTable.t
  def update(rtable, node) do
    bucket_num = get_bucket_number rtable, node
    bucket = rtable.buckets[bucket_num]
    update rtable, node, bucket, bucket_num, Bucket.exists?(bucket)
  end

  # TODO: Improve the update to split it into more granular functions
  @spec update(RoutingTable.t, Node.t, Bucket.t, pos_integer, boolean) :: RoutingTable.t
  defp update(rtable, node, _bucket, bucket_number, true) do
    updated_buckets = Dict.update! rtable.buckets, bucket_number, fn(val) ->
      Bucket.move_to_front val, node
    end
    %{rtable | buckets: updated_buckets}
  end

  defp update(rtable, node, bucket, bucket_number, false) do
    if Bucket.full? bucket do
      # TODO: Handle insertion by evicting old elements after pinging and then adding
      rtable
    else
      updated_buckets = Dict.update! rtable.buckets, bucket_number, fn(val) ->
        Bucket.add_to_front val, node
      end
      %{rtable | buckets: updated_buckets}
    end
  end

  @type closest_nodes_list :: [{Node.t, non_neg_integer}]
  @spec find_closest_node(RoutingTable.t, Node.t, pos_integer) :: closest_nodes_list
  def find_closest_node(rtable, node, count) do
    bucket_num = get_bucket_number rtable, node

    add_nodes_to_list([], rtable, bucket_num)
    |> add_neighbour_nodes(rtable, node, count, bucket_num, 1)
  end

  @spec add_neighbour_nodes(closest_nodes_list, RoutingTable.t, Node.t, pos_integer, non_neg_integer, pos_integer) :: closest_nodes_list
  defp add_neighbour_nodes(result, rtable, node, count, bucket_number, diff_num) when length(result) < count do
    result
    |> add_nodes_to_list(rtable, bucket_number+diff_num)
    |> add_nodes_to_list(rtable, bucket_number-diff_num)
    |> add_neighbour_nodes(rtable, node, count, bucket_number, diff_num+1)
  end

  defp add_neighbour_nodes(result, _rtable, _node, _count, _bucket_number, _diff_num), do: result

  @spec add_nodes_to_list(closest_nodes_list, RoutingTable.t, non_neg_integer) :: closest_nodes_list
  defp add_nodes_to_list(result, rtable, bucket_number) when bucket_number >= 0 and bucket_number < @k_buckets, do:
  [Bucket.get_node_distance_pair(rtable.buckets[bucket_number]) | result]
  defp add_nodes_to_list(result, _rtable, _bucket_number), do: result

  @spec get_bucket_number(RoutingTable.t, Node.t) :: non_neg_integer
  defp get_bucket_number(rtable, node) do
    node
    |> Node.distance(rtable.node.id)
    |> Node.prefix_length
  end
end
