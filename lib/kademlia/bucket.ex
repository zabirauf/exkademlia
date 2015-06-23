defmodule Kademlia.Bucket do
  @moduledoc """
  Kademlia bucket of nodes and associated helper functions to manipulate the bucket
  """

  alias Kademlia.Bucket, as: Bucket
  alias Kademlia.Node, as: Node

  @type t :: %Bucket{nodes: [Node.t], nodes_id_map: %{binary => boolean}}
  defstruct nodes: [], nodes_id_map: %{}

  @bucket_size 20

  @doc """
  Create the bucket
  """
  @spec new :: Bucket.t
  def new do
    %Bucket{nodes: [], nodes_id_map: %{}}
  end

  @doc """
  Does the `node` exists in `bucket`.
  `true` if it exists otherwise `false`
  """
  @spec exists?(Bucket.t, Node.t) :: boolean
  def exists?(bucket, node) do
    Map.has_key?(bucket.nodes_id_map, node.id)
  end

  @doc """
  Checks if the number of nodes in the `bucket` are maximum or not
  `true` if the bucket is full else `false`
  """
  @spec full?(Bucket.t) :: boolean
  def full?(bucket), do: length(bucket.nodes) == @bucket_size

  @doc """
  Gets the node and its distance to `target_node` tuple
  """
  @spec get_node_distance_pair(Bucket.t, Node.t) :: [{Node.t, Node.node_id}]
  def get_node_distance_pair(bucket, target_node) do
    Enum.map bucket.nodes, fn(node) ->
      {node, Node.distance(node, target_node)}
    end
  end

  @doc """
  Removes the `node` from the `bucket` if it exists
  """
  @spec remove(Bucket.t, Node.t) :: Bucket.t
  def remove(bucket, node) do
    remove(bucket, node, Map.has_key?(bucket.nodes_id_map, node.id))
  end

  @spec remove(Bucket.t, Node.t, boolean) :: Bucket.t
  defp remove(bucket, _node, false), do: bucket
  defp remove(bucket, node, true) do
    updated_bucket = %{bucket | nodes: (Enum.filter bucket.nodes, &(&1.id != node.id) )}
    %{updated_bucket | nodes_id_map: Dict.drop(updated_bucket.nodes_id_map, [node.id])}
  end

  @doc """
  Adds the `node` in the front of the list in `bucket`
  """
  @spec add_to_front(Bucket.t, Node.t) :: Bucket.t
  def add_to_front(bucket, node) do
    add_to_front(bucket, node, Dict.has_key?(bucket.nodes_id_map, node.id), full?(bucket))
  end

  @spec add_to_front(Bucket.t, Node.t, boolean, boolean) :: Bucket.t
  defp add_to_front(bucket, _node, _exists, true), do: bucket
  defp add_to_front(bucket, _node, true, _full), do: bucket
  defp add_to_front(bucket, node, false, _full) do
    updated_bucket = %{bucket | nodes: [node|bucket.nodes]}
    %{updated_bucket | nodes_id_map: Dict.put(updated_bucket.nodes_id_map, node.id, true)}
  end

  @doc """
  Removes the `node` from the `bucket` and then add it to the front
  """
  @spec move_to_front(Bucket.t, Node.t) :: Bucket.t
  def move_to_front(bucket, node) do
    bucket
    |> remove(node)
    |> add_to_front(node)
  end

end
