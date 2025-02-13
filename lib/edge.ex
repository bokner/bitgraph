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

  def out_edges(graph, vertex) when is_integer(vertex) do
    Adjacency.row(graph[:adjacency], vertex)
  end

  def in_edges(graph, vertex) when is_integer(vertex) do
    Adjacency.column(graph[:adjacency], vertex)
  end

  def delete_edge(%{adjacency: adjacency} = _graph, from, to) when is_integer(from) and is_integer(to) do
    Adjacency.clear(adjacency, from, to)
  end

  def delete_edges(%{edges: edges, adjacency: adjacency} = graph, vertex) when is_integer(vertex) do
    Enum.reduce(Adjacency.row(adjacency, vertex), edges, fn out_neighbor, acc ->
      Adjacency.clear(adjacency, vertex, out_neighbor)
      Map.delete(acc, {vertex, out_neighbor})
    end)
    |> then(fn edges1 ->
      edges2 = Enum.reduce(Adjacency.column(adjacency, vertex), edges1, fn in_neighbor, acc ->
        Adjacency.clear(adjacency, in_neighbor, vertex)
        Map.delete(acc, {in_neighbor, vertex})
      end)
      Map.put(graph, :edges, edges2)
    end)
  end
end
