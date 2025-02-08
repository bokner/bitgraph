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

end
