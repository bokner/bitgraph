defmodule BitGraph.Adjacency do

  def init_adjacency_table(max_vertices \\ 1024) do
    bit_vector = allocate(max_vertices)
    table_dimension = :math.sqrt(size(bit_vector)) |> ceil()

    %{
      bit_vector: bit_vector,
      table_dimension: table_dimension
    }
  end

  ## Allocate a square matrix for adjacency table
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
      ) when is_integer(i) and is_integer(j) do
    :bit_vector.get(bit_vector, position(i, j, table_dimension))
  end

  def get(_adjacency, _, _) do
    0
  end

  def set(
        %{
          bit_vector: bit_vector,
          table_dimension: table_dimension
        }, i, j
      )  when is_integer(i) and is_integer(j) do
    :bit_vector.set(bit_vector, position(i, j, table_dimension))
  end

  def set(_adjacency, _, _) do
    0
  end

  def clear(
        %{
          bit_vector: bit_vector,
          table_dimension: table_dimension
        }, i, j
      ) when is_integer(i) and is_integer(j) do
    :bit_vector.clear(bit_vector, position(i, j, table_dimension))
  end

  def clear(_adjacency, _, _) do
    0
  end

  def row(
        %{
          table_dimension: table_dimension
        } = table, row
      ) when is_integer(row) do
    Enum.reduce(1..table_dimension, MapSet.new(), fn j, acc ->
      if get(table, row, j) == 1 do
        MapSet.put(acc, j)
      else
        acc
      end
    end)
  end

  def row(_adjacency, _row) do
    MapSet.new()
  end

  def column(
    %{
      table_dimension: table_dimension
    } = table, column
  ) when is_integer(column) do
    Enum.reduce(1..table_dimension, MapSet.new(), fn j, acc ->
      if get(table, j, column) == 1 do
        MapSet.put(acc, j)
      else
        acc
      end
    end)
  end

  def column(_adjacency, _row) do
    MapSet.new()
  end

  def copy(%{bit_vector: {:bit_vector, _, source_ref} = _bit_vector, table_dimension: dimension} = adjacency, edges \\ nil) do
      vector_copy = {:bit_vector, _size, target_ref} = allocate(dimension)
      Map.put(adjacency, :bit_vector, vector_copy)
      |> tap(fn adjacency ->
      if edges do
        copy_from_edges(edges, adjacency)
      else
        copy_from_vector(source_ref, target_ref)
      end
    end)
  end

  defp copy_from_vector(source_ref, vector_copy_ref) do
    Enum.each(1..:atomics.info(source_ref)[:size], fn idx ->
      :atomics.put(vector_copy_ref, idx, :atomics.get(source_ref, idx))
    end)
  end

  defp copy_from_edges(edges, adjacency) do
    Enum.each(edges, fn {{from, to}, _edge_data} ->
      set(adjacency, from, to)
    end)
  end

  defp position(i, j, table_dimension) when is_integer(i) and is_integer(j) do
    (i - 1) * table_dimension + j - 1
  end

  defp position(_i, _j, _d) do
    nil
  end
end
