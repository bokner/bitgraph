defmodule BitGraph.Common do
  alias BitGraph.V

  def vertex_indices_to_ids(graph, indices) do
    Enum.map(indices, fn idx -> V.get_vertex(graph, idx) end)
  end
end
