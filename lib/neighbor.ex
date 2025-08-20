defmodule BitGraph.Neighbor do
  alias BitGraph.Adjacency
  alias Iter.Iterable

  def default_neighbor_finder(finder_type \\ :set)

  def default_neighbor_finder(:set) do
    fn
      graph, vertex, :in ->
        Adjacency.column(graph[:adjacency], vertex)

      graph, vertex, :out ->
        Adjacency.row(graph[:adjacency], vertex)
    end
  end

  def default_neighbor_finder(:iterable) do
    fn
      graph, vertex, :in ->
        Adjacency.column_iterator(graph[:adjacency], vertex)

      graph, vertex, :out ->
        Adjacency.row_iterator(graph[:adjacency], vertex)
    end
  end

  def default_neighbor_iterator() do
    default_neighbor_finder(:iterable)
  end

  def get_neighbor_finder(graph, opts \\ [], default \\ default_neighbor_finder()) do
    Keyword.get(opts, :neighbor_finder) ||
      BitGraph.get_opts(graph)[:neighbor_finder] ||
      default
  end

  def iterate_neighbors(graph, vertex_index, start_value, fun \\ fn neighbor, _acc -> neighbor end, direction \\ :both) when is_integer(vertex_index) do
    iterator = cond do
      direction == :both -> BitGraph.V.neighbors(graph, vertex_index)
      direction == :in -> BitGraph.V.in_neighbors(graph, vertex_index)
      direction == :out -> BitGraph.V.neighbors(graph, vertex_index)
    end

    iterate(iterator, start_value, fun)
  end

  def iterate(iterator, acc, fun) do
    case Iterable.next(iterator) do
      :done -> acc
      {:ok, neighbor, rest} ->
        case fun.(neighbor, acc) do
          {:halt, acc_new} ->
            acc_new
          {:cont, acc_new} ->
            iterate(rest, acc_new, fun)
        end
    end
  end



end
