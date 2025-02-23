defmodule BitGraph.Array do
  def new(size) do
    :atomics.new(size, signed: :false)
  end

  ## Get element by (1-based) index
  def get(array, idx) do
    :atomics.get(array, idx)
  end

  def put(array, idx, value) when is_integer(value) do
    :atomics.put(array, idx, value)
  end

  def to_list(array) do
    Enum.map(1..:atomics.info(array)[:size], fn
      idx -> :atomics.get(array, idx)
    end)
  end
end
