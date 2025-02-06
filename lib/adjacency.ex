defmodule BitGraph.Adjacency do
  def init_adjacency_table(num_vertices \\ 1024) do
    bit_vector = allocate(num_vertices)
    table_dimension = :math.sqrt(size(bit_vector)) |> ceil()

    %{
      bit_vector: bit_vector,
      table_dimension: table_dimension
    }
  end

  ## Allocate a new atomic array with the
  # (squared next power of 2 greater than the number of vertices) / 64
  defp allocate(v) do
    :bit_vector.new(v * v)
  end

  def table_ref(%{bit_vector: bit_vector} = _adjacency_table) do
    elem(bit_vector, 2)
  end

  def size(adjacency_table) do
    :bit_vector.size(adjacency_table)
  end

  def get(
        %{
          bit_vector: bit_vector,
          table_dimension: table_dimension
        }, i, j
      ) do
    :bit_vector.get(bit_vector, pos(i, j, table_dimension))
  end

  def set(
        %{
          bit_vector: bit_vector,
          table_dimension: table_dimension
        }, i, j
      ) do
    :bit_vector.set(bit_vector, pos(i, j, table_dimension))
  end

  def clear(
        %{
          bit_vector: bit_vector,
          table_dimension: table_dimension
        }, i, j
      ) do
    :bit_vector.clear(bit_vector, pos(i, j, table_dimension))
  end

  def row(
        %{
          table_dimension: table_dimension
        } = table, row
      ) do
    Enum.reduce(1..table_dimension, MapSet.new(), fn j, acc ->
      if get(table, row, j) == 1 do
        MapSet.put(acc, j)
      else
        acc
      end
    end)
  end

  def column(
    %{
      table_dimension: table_dimension
    } = table, column
  ) do
    Enum.reduce(1..table_dimension, MapSet.new(), fn j, acc ->
      if get(table, j, column) == 1 do
        MapSet.put(acc, j)
      else
        acc
      end
    end)
end

  defp pos(i, j, table_dimension) do
    (i - 1) * table_dimension + j - 1
  end
end
