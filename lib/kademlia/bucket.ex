defmodule Kademlia.Bucket do
  @moduledoc """
  Kademlia bucket of nodes and associated helper functions to manipulate the bucket
  """

  alias Kademlia.Bucket, as: Bucket
  alias Kademlia.Node, as: Node

  @type t :: %Bucket{nodes: [Node.t], nodes_id_map: %{binary => boolean}}
  defstruct nodes: [], nodes_id_map: %{}

  @doc """
  Create the bucket
  """
  @spec create :: t
  def create do
    %Bucket{}
  end

  @doc """
  Does the `node` exists in `bucket`.
  `true` if it exists otherwise `false`
  """
  @spec exists?(t, Node.t) :: boolean
  def exists?(bucket, node) do
    Map.has_key?(bucket.nodes_id_map, node.id)
  end

  @doc """
  Removes the `node` from the `bucket` if it exists
  """
  @spec remove(t, Node.t) :: t
  def remove(bucket, node) do
    remove(bucket, node, Map.has_key?(bucket.nodes_id_map, node.id))
  end

  @spec remove(t, Node.t, boolean) :: t
  defp remove(bucket, _node, false), do: bucket
  defp remove(bucket, node, true) do
    updated_bucket = %{bucket | nodes: (Enum.filter bucket.nodes, &(&1.id != node.id) )}
    %{updated_bucket | nodes_id_map: Dict.drop(updated_bucket.nodes_id_map, [node.id])}
  end

  @doc """
  Adds the `node` in the front of the list in `bucket`
  """
  @spec add_to_front(t, Node.t) :: t
  def add_to_front(bucket, node) do
    add_to_front(bucket, node, Map.has_key?(bucket.nodes_id_map, node.id))
  end

  @spec add_to_front(t, Node.t, boolean) :: t
  defp add_to_front(bucket, _node, true), do: bucket
  defp add_to_front(bucket, node, false) do
    updated_bucket = %{bucket | nodes: [node|bucket.nodes]}
    %{updated_bucket | nodes_id_map: Dict.put(updated_bucket.nodes_id_map, node.id, true)}
  end

  @doc """
  Removes the `node` from the `bucket` and then add it to the front
  """
  @spec move_to_front(t, Node.t) :: t
  def move_to_front(bucket, node) do
    bucket
    |> remove(node)
    |> add_to_front(node)
  end

end
