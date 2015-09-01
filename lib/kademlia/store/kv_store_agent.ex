defmodule Kademlia.Store.KVStoreAgent do
  @moduledoc """
  The agent for the key value store
  """

  require Logger
  alias Kademlia.Store.KVStore, as: KVStore

  @type key :: KVStore.key

  @type value :: KVStore.value

  @type on_get :: KVStore.on_get

  @doc """
  Start the agent for the key value store
  """
  def start_link(module) do
    Agent.start_link(fn -> module.new end, name: __MODULE__)
  end

  @doc """
  Puts the `value` at the `key` in the provided `kvstore`
  Returns `{:ok, kvstore}` or returns `{:error, reason}`
  """
  @spec put(key, value) :: :ok
  def put(key, value) do
    Logger.debug "KVStoreAgent.put #{inspect(key)}"
    Agent.update __MODULE__, fn(kvstore) ->
      case KVStore.put(kvstore, key, value) do
        {:ok, kvs} ->
          kvs
        {:error, e} ->
          Logger.debug e
      end
    end
  end

  @doc """
  Gets the value of the `key` in the provided `kvstore`
  Returns `{:ok, value}` if key exists else `{:error, :not_found}` if key does not exist
  """
  @spec get(key) :: on_get
  def get(key) do
    Logger.debug "KVStoreAgent.get #{inspect(key)}"
    Agent.get __MODULE__, fn(kvstore) ->
      KVStore.get(kvstore, key)
    end
  end

  @doc """
  Tells if the kvstore has the `key`
  """
  @spec has_key?(key) :: boolean
  def has_key?(key) do
    Logger.debug "KVStoreAgent.has_key? #{inspect(key)}"
    Agent.get __MODULE__, fn(kvstore) ->
      KVStore.has_key?(kvstore, key)
    end
  end

  @doc """
  Delete the entry related to `key`
  """
  @spec delete(key) :: :ok
  def delete(key) do
    Logger.debug "KVStoreAgent.delete #{inspect(key)}"
    Agent.update __MODULE__, fn(kvstore) ->
      case KVStore.delete(kvstore, key) do
        {:ok, kvs} ->
          kvs
        {:error, e} ->
          Logger.debug e
      end
    end
  end

end
