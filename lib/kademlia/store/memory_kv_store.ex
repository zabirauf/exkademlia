defimpl Kademlia.Store.KVStore, for: HashDict do

  def put(kvstore, key, value), do: {:ok, Dict.put(kvstore, key, value)}

  def get(kvstore, key) do
    case Dict.get(kvstore, key, nil) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  def has_key?(kvstore, key), do: Dict.has_key?(kvstore, key)

  def delete(kvstore, key), do: {:ok, Dict.delete(kvstore, key)}

end

defmodule Kademlia.Store.KVStore.MemoryKVStore do
  @moduledoc """
  Memory key value sorage using HashDict
  """
  def create(), do: %HashDict{}
end
