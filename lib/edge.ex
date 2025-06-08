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

  def edges(%{edges: edges} = _graph) do
    edges
  end

  def out_neighbors(graph, vertex, opts \\ []) when is_integer(vertex) do
    neighbor_finder = Keyword.get(opts, :neighbor_finder, default_neighbor_finder())
    neighbor_finder.(graph, vertex, :out)
  end

  def in_neighbors(graph, vertex, opts \\ []) when is_integer(vertex) do
    neighbor_finder = Keyword.get(opts, :neighbor_finder, default_neighbor_finder())
    neighbor_finder.(graph, vertex, :in)
  end

  def neighbors(graph, vertex, opts \\ []) when is_integer(vertex) do
    MapSet.union(
      in_neighbors(graph, vertex, opts),
      out_neighbors(graph, vertex, opts)
    )
  end

  def default_neighbor_finder() do
    fn graph, vertex, :in ->
      Adjacency.column(graph[:adjacency], vertex)
      graph, vertex, :out ->
        Adjacency.row(graph[:adjacency], vertex)
      end
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
