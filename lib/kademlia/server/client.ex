defmodule Kademlia.Server.Client do
  @moduledoc """
  The client behavior that should be implemented for different server implementations
  """
  use Behaviour
  alias Kademlia.Server.Contract, as: Contract

  @doc "Ping the node"
  defcallback ping(request :: Contract.PingRequest.t) :: Contract.PingResponse.t

  @doc "Find a node in the network. The response should never include the node being contacted"
  defcallback find_node(request :: Contract.FindNodeRequest.t) :: Contract.FindNodeResponse.t

  @doc "Find a value in the network"
  defcallback find_value(request :: Contract.FindValueRequest.t) :: Contract.FindValueResponse.t

  @doc "Store a value in the network"
  defcallback store_value(request :: Contract.StoreValueRequest.t) :: Contract.StoreValueResponse.t

end
