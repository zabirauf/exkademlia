defmodule Kademlia.RoutingTable do

  alias Kademlia.RoutingTable, as: RoutingTable
  alias Kademlia.Node, as: Node

  @type t :: %RoutingTable{id: Node.node_id, buckets: [any]}
  defstruct id: <<>>, buckets: []

end
