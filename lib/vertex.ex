defmodule BitGraph.V do
  def init_vertices(opts) do
    ## `id_to_pos` is a map from vertex identifiers to their positions in the adjacency table
    ## `pos_to_vertex` is a map from vertex positions in the adjacency table to vertices
    %{id_to_pos: Map.new(), pos_to_vertex: Map.new(), num_vertices: 0, max_vertices: opts[:max_vertices] || 1024}
  end

  def new(vertex, opts) do
    %{vertex: vertex, opts: opts}
  end

  def add_vertex(%{vertices: vertices} = graph, vertex, opts \\ []) do
    vertices
    |> add_vertex_impl(vertex, opts)
    |> then(fn vertices -> Map.put(graph, :vertices, vertices) end)
  end

  defp add_vertex_impl(
      %{
        id_to_pos: id_to_pos_map,
        pos_to_vertex: pos_to_vertex_map,
        num_vertices: num_vertices
        } = vertices, vertex, opts) do
    vertex_rec = new(vertex, opts)
    if Map.has_key?(id_to_pos_map, vertex_rec.vertex) do
      vertices
    else
      num_vertices = num_vertices + 1
      %{vertices |
        num_vertices: num_vertices,
        id_to_pos: Map.put(id_to_pos_map, vertex_rec.vertex, num_vertices),
        pos_to_vertex: Map.put(pos_to_vertex_map, num_vertices, vertex_rec)
    }
    end
  end

end
