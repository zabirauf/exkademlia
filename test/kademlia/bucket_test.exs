defmodule Kademlia.BucketTest do
  use ExUnit.Case

  require Logger
  alias Kademlia.Node, as: Node
  alias Kademlia.Bucket, as: Bucket

  test "add node to bucket and see if it exists" do
    n1 = Node.new
    n2 = Node.new
    n3 = Node.new

    bucket = Bucket.new
    |> Bucket.add_to_front(n1)
    |> Bucket.add_to_front(n2)

    assert true == Bucket.exists?(bucket, n2)
    assert false == Bucket.exists?(bucket, n3)
  end

  test "get node distance pairs" do
    n1 = Node.new
    n2 = Node.new

    bucket = Bucket.new
    |> Bucket.add_to_front(n1)
    |> Bucket.add_to_front(n2)

    node_distances = Bucket.get_node_distance_pair(bucket, n2)
    assert true == Enum.any?(node_distances, fn({_node, distance}) ->
      distance == << 0 :: size(160) >>
    end)

    # Check if all the elements are valid distance pairs
    Enum.map(node_distances, fn(pair) ->
      assert {_node, _distance} = pair
    end)
  end

  test "remove a node from bucket" do
    n1 = Node.new

    bucket = Bucket.new
    |> Bucket.add_to_front(n1)

    assert length(bucket.nodes) == 1

    bucket = Bucket.remove(bucket, n1)

    # After removing the single node the bucket should be empty which is same as a newly created bucket
    assert ^bucket = Bucket.new
  end

  test "move a node to front in the bucket" do
    n1 = Node.new
    n2 = Node.new
    n3 = Node.new

    bucket = Bucket.new
    |> Bucket.add_to_front(n3)
    |> Bucket.add_to_front(n2)
    |> Bucket.add_to_front(n1)

    [h|_] = bucket.nodes
    assert ^h = n1

    bucket = Bucket.move_to_front(bucket, n3)

    [h|_] = bucket.nodes
    assert ^h = n3
  end

  test "is the bucket full and try adding after the bucket is full" do
    bucket = Enum.reduce 1..20, Bucket.new, fn(_x, acc) ->
      Bucket.add_to_front(acc, Node.new)
    end

    assert true == Bucket.full?(bucket)

    updated_bucket = Bucket.add_to_front(bucket, Node.new)

    assert ^bucket = updated_bucket
  end
end
