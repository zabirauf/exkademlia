defmodule Kademlia.Server.Client do
  @moduledoc """
  The client behavior that should be implemented for different server implementations.
  This is an asyn client
  """
  use Behaviour

  @doc "Start"
  defcallback start_link(name :: String.t, node :: Kademlia.Node.t, sender :: Kademlia.Node.t, network_id :: String.t, opts :: Keyword.t) :: {:ok, any} | {:error, any}

  @doc "Ping the node"
  defcallback ping(client :: pid) :: pid

  @doc "Find a node in the network. The response should never include the node being contacted"
  defcallback find_node(client :: pid, target :: Kademlia.Node.node_id) :: any

  @doc "Find a value in the network"
  defcallback find_value(client :: pid, key :: term) :: any

  @doc "Store a value in the network"
  defcallback store_value(client :: pid, key :: term, value :: binary) :: any

end
