defmodule BitGraph.E do
  alias BitGraph.V

  defstruct from: nil,
            to: nil,
            opts: []

  @type t :: %__MODULE__{
          from: any(),
          to: any(),
          opts: Keyword.t()
        }
  alias BitGraph.Adjacency
  alias Iter.Iterable

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

  def edge?(graph, from, to) when is_integer(from) and is_integer(to) do
    Adjacency.get(graph[:adjacency], from, to) == 1
  end

  def get_edge(%{edges: edges} = _graph, from, to) when is_integer(from) and is_integer(to) do
    Map.get(edges, {from, to}, new(from, to))
  end

  def edges(graph) do
    graph
    |> BitGraph.vertices()
    |> Enum.reduce(MapSet.new(), fn v, acc -> MapSet.union(acc, BitGraph.out_edges(graph, v)) end)
  end

  def in_edges(graph, to, opts \\ []) do
    Iterable.map(
      V.in_neighbors(graph, to, opts),
      fn neighbor -> get_edge(graph, neighbor, to) end
    )
  end

  def out_edges(graph, from, opts \\ []) do
    Iterable.map(
      V.out_neighbors(graph, from, opts),
      fn neighbor -> get_edge(graph, from, neighbor) end
    )
  end

  def edges(graph, vertex, opts \\ []) do
    Iterable.concat([
      in_edges(graph, vertex, opts),
      out_edges(graph, vertex, opts)
    ])
  end

  def delete_edge(%{adjacency: %{bit_vector: false}} = graph, _from, _to) do
    graph
  end

  def delete_edge(%{adjacency: adjacency, edges: edges} = graph, from, to)
      when is_integer(from) and is_integer(to) do
    Adjacency.clear(adjacency, from, to)

    edges
    |> Map.delete({from, to})
    |> then(fn updated_edges -> Map.put(graph, :edges, updated_edges) end)
  end

  def delete_edges(%{adjacency: %{bit_vector: false}} = graph, _vertex) do
    graph
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
