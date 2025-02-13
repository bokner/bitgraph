defmodule BitGraph.V do
  def init_vertices(opts) do
    ## `id_to_index` is a map from vertex identifiers to their positions in the adjacency table
    ## `index_to_vertex` is a map from vertex positions in the adjacency table to vertices
    %{id_to_index: Map.new(), index_to_vertex: Map.new(), num_vertices: 0, max_vertices: opts[:max_vertices] || 1024}
  end

  def new(vertex, opts) do
    %{vertex: vertex, opts: opts}
  end

  def add_vertex(%{vertices: vertices} = graph, vertex, opts \\ []) do
    vertices
    |> add_vertex_impl(vertex, opts)
    |> then(fn vertices -> Map.put(graph, :vertices, vertices) end)
  end

  def delete_vertex(%{vertices: vertices} = graph, vertex) do
    vertices
    |> delete_vertex_impl(vertex)
    |> then(fn vertices -> Map.put(graph, :vertices, vertices) end)
  end


  defp add_vertex_impl(
      %{
        id_to_index: id_to_index_map,
        index_to_vertex: index_to_vertex_map,
        num_vertices: num_vertices
        } = vertices, vertex, opts) do
    vertex_rec = new(vertex, opts)
    if Map.has_key?(id_to_index_map, vertex_rec.vertex) do
      vertices
    else
      num_vertices = num_vertices + 1
      %{vertices |
        num_vertices: num_vertices,
        id_to_index: Map.put(id_to_index_map, vertex_rec.vertex, num_vertices),
        index_to_vertex: Map.put(index_to_vertex_map, num_vertices, vertex_rec)
    }
    end
  end

  defp delete_vertex_impl(
      %{
        id_to_index: id_to_index_map,
        index_to_vertex: index_to_vertex_map,
        num_vertices: num_vertices
        } = vertices, vertex) do
    {pos, id_to_index_map} = Map.pop(id_to_index_map, vertex)
    index_to_vertex_map = pos && Map.delete(index_to_vertex_map, pos) || index_to_vertex_map
    num_vertices = pos && (num_vertices - 1) || num_vertices
    %{vertices |
      id_to_index: id_to_index_map,
      index_to_vertex: index_to_vertex_map,
      num_vertices: num_vertices
    }
  end
end
