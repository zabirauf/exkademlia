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
  @spec create(Node.t) :: RoutingTable.t
  def create(node) do
    table = %RoutingTable{node: node, buckets: %{}}

    # Initializing the table with the buckets
    Enum.reduce 0..@k_buckets-1, table, fn(x, acc) ->
      %{acc | buckets: Dict.put(acc.buckets, x, Bucket.create)}
    end
  end

end
