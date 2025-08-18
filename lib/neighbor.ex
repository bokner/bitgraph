defmodule BitGraph.Neighbor do
  alias BitGraph.Adjacency

  def default_neighbor_finder(finder_type \\ :enum)

  def default_neighbor_finder(:enum) do
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

  def get_neighbor_finder(graph, opts \\ [], default \\ nil) do
    Keyword.get(opts, :neighbor_finder) ||
      BitGraph.get_opts(graph)[:neighbor_finder] ||
      default
  end
end
