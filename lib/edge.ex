defmodule BitGraph.E do
  defstruct from: nil,
            to: nil,
            opts: []

  @type t :: %__MODULE__{
          from: any(),
          to: any(),
          opts: Keyword.t()
        }
  alias BitGraph.Adjacency

  def init_edges(_opts) do
    Map.new()
  end

  def new(from, to, opts \\ []) do
    %__MODULE__{
      from: from,
      to: to,
      opts: opts
    }
  end

  def add_edge(graph, from, to) when is_integer(from) and is_integer(to) do
      Adjacency.set(graph[:adjacency], from, to)
  end

  def edge?(graph, from, to) when  is_integer(from) and is_integer(to) do
    Adjacency.get(graph[:adjacency], from, to) == 1
  end

  def edges(graph) do
    graph
    |> BitGraph.vertices()
    |> Enum.reduce(MapSet.new(), fn v, acc -> MapSet.union(acc, BitGraph.out_edges(graph, v)) end)
  end

  def out_neighbors(graph, vertex, opts \\ [])

  def out_neighbors(graph, vertex, opts) when is_list(opts) do
    out_neighbors(graph, vertex, get_neighbor_finder(graph, opts))
  end

  def out_neighbors(graph, vertex, neighbor_finder) when is_integer(vertex) and is_function(neighbor_finder, 3) do
    neighbor_finder.(graph, vertex, :out)
  end

  def in_neighbors(graph, vertex, opts \\ [])

  def in_neighbors(graph, vertex, opts) when is_list(opts) do
    in_neighbors(graph, vertex, get_neighbor_finder(graph, opts))
  end

  def in_neighbors(graph, vertex, neighbor_finder) when is_integer(vertex) and is_function(neighbor_finder, 3) do
    neighbor_finder.(graph, vertex, :in)
  end

  def neighbors(graph, vertex, opts \\ [])

  def neighbors(graph, vertex, opts) when is_list(opts) do
    neighbors(graph, vertex, get_neighbor_finder(graph, opts))
  end

  def neighbors(graph, vertex, neighbor_finder) when is_integer(vertex) and is_function(neighbor_finder, 3) do
    MapSet.union(
      in_neighbors(graph, vertex, neighbor_finder),
      out_neighbors(graph, vertex, neighbor_finder)
    )
  end

  def default_neighbor_finder() do
    fn graph, vertex, :in ->
      Adjacency.column(graph[:adjacency], vertex)
      graph, vertex, :out ->
        Adjacency.row(graph[:adjacency], vertex)
      end
  end

  defp get_neighbor_finder(graph, opts) do
    Keyword.get(Keyword.merge(graph[:opts], opts), :neighbor_finder, default_neighbor_finder())
  end

  def out_degree(graph, vertex, opts \\ []) when is_integer(vertex) do
    out_neighbors(graph, vertex, opts) |> MapSet.size()
  end

  def in_degree(graph, vertex, opts \\ []) when is_integer(vertex) do
    in_neighbors(graph, vertex, opts) |> MapSet.size()
  end

  def delete_edge(%{adjacency: adjacency, edges: edges} = graph, from, to) when is_integer(from) and is_integer(to) do
    Adjacency.clear(adjacency, from, to)
    edges
    |> Map.delete({from, to})
    |> then(fn updated_edges -> Map.put(graph, :edges, updated_edges) end)
  end

  def delete_edges(%{adjacency: adjacency} = graph, vertex) when is_integer(vertex) do
    Enum.reduce(Adjacency.row(adjacency, vertex), graph, fn out_neighbor, acc ->
      delete_edge(acc, vertex, out_neighbor)
    end)
    |> then(fn graph ->
      Enum.reduce(Adjacency.column(adjacency, vertex), graph, fn in_neighbor, acc ->
        delete_edge(acc, in_neighbor, vertex)
      end)
    end)
  end
end
