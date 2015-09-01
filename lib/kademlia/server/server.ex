defmodule Kademlia.Server.Server do

  use Behaviour
  alias Kademlia.Node

  @doc """
  Start the server
  """
  defcallback start_link(node :: Node.t, network_id :: String.t) :: {:ok, any} | {:error, any}
end
