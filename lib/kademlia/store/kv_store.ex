defprotocol Kademlia.Store.KVStore do

  @type t :: any

  @type kvstore :: t

  @type key :: term

  @type value :: term

  @type error :: {:error, term}

  @type on_kvstore_change :: {:ok, kvstore} | error

  @type on_get :: {:ok, value} | {:error, :not_found} | error 

  @doc """
  Puts the `value` at the `key` in the provided `kvstore`
  Returns `{:ok, kvstore}` or returns `{:error, reason}`
  """
  @spec put(kvstore, key, value) :: on_kvstore_change
  def put(kvstore, key, value)

  @doc """
  Gets the value of the `key` in the provided `kvstore`
  Returns `{:ok, value}` if key exists else `{:error, :not_found}` if key does not exist
  """
  @spec get(kvstore, key) :: on_get
  def get(kvstore, key)

  @doc """
  Tells if the kvstore has the `key`
  """
  @spec has_key?(kvstore, key) :: boolean
  def has_key?(kvstore, key)

  @doc """
  Delete the entry related to `key`
  """
  @spec delete(kvstore, key) :: on_kvstore_change
  def delete(kvstore, key)

end
