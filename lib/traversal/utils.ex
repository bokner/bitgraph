defmodule BitGraph.Traversal.Utils do
  @doc """
  Builds list of vertex indices, assumes `vertices` are list or set of vertex ids.
  """
  def build_vertex_indices(graph, :all) do
    BitGraph.vertex_indices(graph)
  end

  def build_vertex_indices(graph, vertices)
      when is_list(vertices) or is_struct(vertices, MapSet) do
    Enum.map(vertices, fn v -> BitGraph.V.get_vertex_index(graph, v) end)
  end

  def build_vertex_indices(graph, vertex) do
    build_vertex_indices(graph, [vertex])
  end
end
