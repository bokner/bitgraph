defmodule BitGraph.E do
  defstruct from: nil,
            to: nil,
            opts: []

  @type t :: %__MODULE__{
          from: integer(),
          to: integer(),
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

  def out_neighbors(graph, vertex) when is_integer(vertex) do
    Adjacency.row(graph[:adjacency], vertex)
  end

  def in_neighbors(graph, vertex) when is_integer(vertex) do
    Adjacency.column(graph[:adjacency], vertex)
  end

  def neighbors(graph, vertex) when is_integer(vertex) do
    MapSet.union(
      in_neighbors(graph, vertex),
      out_neighbors(graph, vertex)
    )
  end

  def out_degree(graph, vertex) when is_integer(vertex) do
    out_neighbors(graph, vertex) |> MapSet.size()
  end

  def in_degree(graph, vertex) when is_integer(vertex) do
    in_neighbors(graph, vertex) |> MapSet.size()
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
