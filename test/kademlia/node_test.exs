defmodule Kademlia.NodeTest do
  use ExUnit.Case
  alias Kademlia.Node, as: Node

  @test_ip "127.0.0.1"
  @test_port "9000"
  test "Create new node" do
    node = Node.new(@test_ip, @test_port)
    assert node.endpoint == @test_ip
    assert node.port == @test_port
    assert 20 = byte_size(node.id)
  end

  test "Encoding and decoding id to hex" do
    id = Node.create_rand_id
    hex = Node.id_to_hexstr id
    decoded_id = Node.hexstr_to_id hex

    assert id == decoded_id
  end

  test "Distance between nodes" do
    id1 = %Node{id: << 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 >>}
    id2 = %Node{id: << 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19, 18 >>}
    expected_distance = << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1 >>

    distance = Node.distance(id1, id2)
    assert distance == expected_distance
  end

  test "Prefix length" do
    assert 16 = Node.prefix_length(<< 0, 0, 0xFF >>)
    assert 0 = Node.prefix_length(<< 0xFF, 0, 0 >>)
    assert 12 = Node.prefix_length(<< 0, 0b00001111, 0 >>)

    # TODO: This seems like a weired behaviour. Figure out the prefix length algo
    assert 7 = Node.prefix_length(<< 0 >>)
  end
end
