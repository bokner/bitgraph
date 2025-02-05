defmodule BitGraph.Adjacency do
  def init_adjacency_table(opts \\ default_options()) do
    max_vertices = Keyword.get(opts, :initial_vertices)
    Arrays.new([allocate(max_vertices)])
  end

  ## Allocate a new atomic array with the
  # (squared next power of 2 greater than the number of vertices) / 64
  def allocate(v) do
    v
    |> :math.log2()
    |> ceil
    |> then(fn p -> :math.pow(4, p) |> ceil end)
    |> :bit_vector.new()
  end

  def table_ref(adjacency_table) do
    elem(adjacency_table, 2)
  end

  def size(adjacency_table) do
    :bit_vector.size(adjacency_table)
  end

  def get(adjacency_table, i, j) do
    :bit_vector.get(adjacency_table, i, j)
  end

  defp default_options() do
    [
      initial_vertices: 1024
    ]
  end
end
