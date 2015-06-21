defmodule Kademlia.Node do
  @docmodule """
  Contains the Node structure which has an Id, port and endpont (IPv4, IPv6 or Domain name)
  Also contains the functions for checking distance between nodes and creating ids etc
  """

  use Bitwise
  alias Kademlia.Node, as: Node

  @type node_id :: << _ :: _ * 160 >>
  @type t :: %Node{id: node_id, port: number, endpoint: binary}
  defstruct id: <<>>, port: 0, endpoint: nil

  @default_id_length 20 # If changed then change the typespec of node_id to be _ * (8*@default_id_length)

  @doc """
  Create a random 20 byte id
  """
  @spec create_rand_id(pos_integer) :: node_id
  def create_rand_id(length \\ @default_id_length) do
    :crypto.rand_bytes(length)
  end

  @doc """
  Converts `node_id` to a hexadecimal string
  """
  @spec id_to_hexstr(node_id) :: String.t
  def id_to_hexstr(node_id), do: Hexate.encode(node_id)

  @doc """
  Converts a `hexstr` to a binary
  """
  @spec hexstr_to_id(String.t) :: node_id
  def hexstr_to_id(hexstr), do: Hexate.decode(hexstr)

  @doc """
  Calculates the XOR distance between two nodes by computing bytewise XOR of the IDs
  """
  @spec distance(t, t) :: node_id
  def distance(node, other_node) do
    id_tuple = Enum.zip(:binary.bin_to_list(node.id), :binary.bin_to_list(other_node.id))

    id_tuple
    |> Enum.map(fn {bin1, bin2} ->
      bin1 ^^^ bin2
    end)
    |> :binary.list_to_bin
  end

  @doc """
  Calculates the length of zero bits in the most significant part of the `node_id`
  """
  @spec prefix_length(node_id) :: non_neg_integer
  def prefix_length(node_id), do: prefix_length(node_id, 0)

  @spec prefix_length(bitstring, non_neg_integer) :: non_neg_integer
  defp prefix_length(<< 0 :: 1, rest :: bitstring >>, acc), do: prefix_length(rest, acc+1)
  defp prefix_length(<< _ :: 1, _rest :: bitstring >>, acc), do: acc
  defp prefix_length(<<>>, acc), do: acc

end
