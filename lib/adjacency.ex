defmodule BitGraph.Adjacency do
  def init_adjacency_table(opts \\ []) do
    opts = Keyword.merge(default_opts(), opts)
    max_vertices = Keyword.get(opts, :max_vertices)
    allocate? = Keyword.get(opts, :allocate_adjacency_table?)

    %{
      bit_vector: allocate? && allocate(max_vertices),
      table_dimension: max_vertices
    }
  end

  defp default_opts() do
    [
      max_vertices: 1024,
      allocate_adjacency_table?: true
    ]
  end

  ## Allocate a square matrix for adjacency table
  defp allocate(v) do
    :bit_vector.new(v * v)
  end

  def table_ref(%{bit_vector: bit_vector} = _adjacency_table) do
    elem(bit_vector, 2)
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

  def row(table, row) do
    row_iterator(table, row)
    |> Iter.Iterable.to_list()
    |> MapSet.new()
  end

  def row_iterator(
        %{
          table_dimension: table_dimension
        } = table, row
      ) when is_integer(row) do
        Iter.Iterable.Filterer.new(1..table_dimension,
          fn j -> get(table, row, j) == 1
      end)
  end

  def column(
    table, column
  ) do
    column_iterator(table, column)
    |> Iter.Iterable.to_list()
    |> MapSet.new()
  end

  def column_iterator(
        %{
          table_dimension: table_dimension
        } = table,
        column
      )
      when is_integer(column) do
    Iter.Iterable.Filterer.new(
      1..table_dimension,
      fn i -> get(table, i, column) == 1 end
    )
  end

  def copy(
        %{bit_vector: {:bit_vector, source_ref} = _bit_vector, table_dimension: dimension} =
          adjacency,
        edges \\ nil
      ) do
    vector_copy = {:bit_vector, target_ref} = allocate(dimension)

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
