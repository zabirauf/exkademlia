defmodule Kademlia.RoutingTable do
  require Logger
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
    update rtable, node, bucket, bucket_num, Bucket.exists?(bucket, node)
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

  @doc """
  Finds the closes node to a node in the routing table
  The alogrithm is as follows
    1. Find the bucket the `node` falls in
    2. Take all the nodes in that bucket and compute its distance from `node` and add it to return list
    3. If the number of nodes is less than `count` keep repeating the step 2 with the negbouring bucket i.e. bucket_number + n and bucket_numer - n where n = [1..]
    4. Sort the list by increasing order of distance
    5. Take the `count` elements from the result and return
  """
  @type closest_nodes_list :: [{Node.t, Node.node_id}]
  @spec find_closest_node(RoutingTable.t, Node.t, pos_integer) :: closest_nodes_list
  def find_closest_node(rtable, node, count) do
    bucket_num = get_bucket_number rtable, node

    add_nodes_to_list([], rtable, node, bucket_num)
    |> add_neighbour_nodes(rtable, node, count, bucket_num, 1)
    |> Enum.sort(fn({_node1, distance1}, {_node2, distance2}) ->
      distance1 < distance2
    end)
    |> Enum.take(count)
  end

  @doc """
  Finds the closest node the the `id` upto `count`
  """
  @spec find_closest(RoutingTable.t, Node.node_id, pos_integer) :: closest_nodes_list
  def find_closest(rtable, id, count) do
    node = %Node{id: id}
    find_closest_node(rtable, node, count)
  end

  @doc """
  Add neighbour nodes to the list upto `count`
  It will switch between neighbour on the left and then on the right
  """
  @spec add_neighbour_nodes(closest_nodes_list, RoutingTable.t, Node.t, pos_integer, non_neg_integer, pos_integer) :: closest_nodes_list
  defp add_neighbour_nodes(result, rtable, node, count, bucket_number, diff_num) when length(result) < count  do
    if ((bucket_number-diff_num) >= 0 || (bucket_number+diff_num) < @k_buckets) do
      result
      |> add_nodes_to_list(rtable, node, bucket_number+diff_num)
      |> add_nodes_to_list(rtable, node, bucket_number-diff_num)
      |> add_neighbour_nodes(rtable, node, count, bucket_number, diff_num+1)
    else
      result
    end
  end

  defp add_neighbour_nodes(result, _rtable, _node, _count, _bucket_number, _diff_num), do: result

  @doc """
  It add the nodes distance pair to list
    1. Get node distance of nodes with `node` from bucket `bucket_number`
    2. Add the nodes distance pair to `result`
  """
  @spec add_nodes_to_list(closest_nodes_list, RoutingTable.t, Node.t, non_neg_integer) :: closest_nodes_list
  defp add_nodes_to_list(result, rtable, node, bucket_number) when bucket_number >= 0 and bucket_number < @k_buckets do
    distance_pair = Bucket.get_node_distance_pair(rtable.buckets[bucket_number], node) 
    case distance_pair do
      [] -> result
      dp -> List.flatten([dp | result])
    end
  end

  defp add_nodes_to_list(result, _rtable, _node, _bucket_number), do: result

  @spec get_bucket_number(RoutingTable.t, Node.t) :: non_neg_integer
  defp get_bucket_number(rtable, node) do
    node
    |> Node.distance(rtable.node)
    |> Node.prefix_length
  end
end
