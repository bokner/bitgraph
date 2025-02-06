defmodule BitGraph do
  @moduledoc """
  Documentation for `Bitgraph`.
  """

  @doc """

  """
  alias BitGraph.{V, E, Impl}

  def new(opts \\ []) do
    %{vertices: V.init_vertices(), edges: E.init_edges(), adjacency: Impl.init_adjacency_table()}
  end
end
