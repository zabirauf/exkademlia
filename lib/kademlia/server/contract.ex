defmodule Kademlia.Server.Contract do

  defmodule Header do
    @moduledoc """
    Header part of all the request and response in Kademlia inter node communication
    It contains the sender information, a network id which is an arbitrary string to
    make sure multiple instance of kademlia don't conflict and it contains a random message_id
    """
    @type message_id :: << _ :: _ * 160 >>

    @type t :: %Kademlia.Server.Contract.Header{sender: Kademlia.Node.t, network_id: String.t, message_id: message_id}
    defstruct sender: nil, network_id: "", message_id: nil
  end

  defmodule PingRequest do
    @moduledoc """
    Request to send Ping to a node
    """
    @type t :: %PingRequest{header: Header.t}
    defstruct header: nil
  end

  defmodule PingResponse do
    @moduledoc """
    Response for the ping request
    """
    @type t :: %PingResponse{header: Header.t}
    defstruct header: nil
  end

  defmodule FindNodeRequest do
    @moduledoc """
    Request to find a node in the network
    """
    @type t :: %FindNodeRequest{header: Header.t, target: Kademlia.Node.node_id}
    defstruct header: nil, target: nil
  end

  defmodule FindNodeResponse do
    @moduledoc """
    Response of the find node request containing the list of nodes including or closes to target node
    """
    @type t :: %FindNodeResponse{header: Header.t, nodes: [Kademlia.Node.t]}
    defstruct header: nil, nodes: []
  end

  defmodule FindValueRequest do
    @moduledoc """
    Request to find a value in the network
    """
    # TODO: See what the type of the key would be
    @type t :: %FindValueRequest{header: Header.t, key: term}
    defstruct header: nil, key: nil
  end

  defmodule FindValueResponse do
    @moduledoc """
    Response for finding value in the network. It will either containt the `value` or a list of `nodes`
    which should be explored for finding the value
    """
    @type t :: %FindValueResponse{header: Header.t, value: binary, nodes: [Kademlia.Node.t]}
    defstruct header: nil, value: nil, nodes: []
  end

  defmodule StoreValueRequest do
    @moduledoc """
    Request to store a value for a given key
    """
    # TODO: See what the type of the key would be
    @type t :: %StoreValueRequest{header: Header.t, key: term, value: binary}
    defstruct header: nil, key: nil, value: nil
  end

  defmodule StoreValueResponse do
    @moduledoc """
    Response for storing a value for the given key. The status values are as follows
      1. STORED = 0
      2. ERROR_NO_SPACE = 1
      3. ERROR_GENERIC = 2
    """
    @type status :: 0 | 1 | 2
    @type t :: %StoreValueResponse{header: Header.t, status: status}
    defstruct header: nil, status: 0
  end
end
