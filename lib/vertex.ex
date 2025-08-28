defmodule BitGraph.V do
  import BitGraph.Neighbor
  alias Iter.{Iterable, Iterable.Filterer}

  def init_vertices(opts) do
    ## `vertex_to_index` is a map from vertex labels to their indices
    ## `index_to_vertex` is a map from vertex indices to vertex records
    %{
      vertex_to_index: Map.new(),
      index_to_vertex: Map.new(),
      num_vertices: 0,
      max_vertices: opts[:max_vertices] || 1024
    }
  end

  def new(vertex, opts) do
    %{vertex: vertex, opts: opts}
  end

  defp index_to_vertex_map(graph) do
    graph[:vertices][:index_to_vertex]
  end

  defp vertex_to_index_map(graph) do
    graph[:vertices][:vertex_to_index]
  end

  def vertices(graph, mapper \\ &(&1.vertex)) do
    case BitGraph.get_subgraph(graph) do
      nil ->
        graph
        |> index_to_vertex_map()
        |> Enum.reduce(MapSet.new(), fn {_idx, vertex}, acc ->
          MapSet.put(acc, mapper.(vertex))
        end)
      subgraph ->
        MapSet.new(subgraph, fn index -> mapper.(index_to_vertex_map(graph)[index]) end)
    end
  end

  def vertex_indices(graph) do
    case BitGraph.get_subgraph(graph) do
      nil -> index_to_vertex_map(graph) |> Map.keys()
      subgraph -> subgraph
    end
  end

  def num_vertices(graph) do
    #graph[:vertices][:num_vertices]
    subgraph = BitGraph.get_subgraph(graph)
    if subgraph do
      Iterable.count(subgraph)
    else
      graph[:vertices][:num_vertices]
    end
  end

  def add_vertex(%{vertices: vertices} = graph, vertex, opts \\ []) do
    vertices
    |> add_vertex_impl(vertex, opts)
    |> then(fn vertices -> Map.put(graph, :vertices, vertices) end)
  end

  def get_vertex_index(graph, vertex) do
    idx = Map.get(vertex_to_index_map(graph), vertex)
    case BitGraph.get_subgraph(graph) do
      nil -> idx
      subgraph -> if Iterable.member?(subgraph, idx), do: idx
    end
  end

  def get_vertex(graph, vertex_idx) when is_integer(vertex_idx) do
    get_vertex(graph, vertex_idx, [:vertex])
  end

  def get_vertex(graph, vertex_idx, aux \\ [])

  def get_vertex(_graph, vertex_idx, _aux) when is_nil(vertex_idx) do
    nil
  end

  def get_vertex(graph, vertex_idx, aux) when is_integer(vertex_idx) do
    subgraph = BitGraph.get_subgraph(graph)

    if !subgraph || (subgraph && Iterable.member?(subgraph, vertex_idx)) do
      get_vertex_impl(graph, vertex_idx, aux)
    end

  end

  def get_vertex(graph, vertex, aux) do
    get_vertex(graph, vertex_to_index_map(graph) |> get_in([vertex | aux]))
  end

  defp get_vertex_impl(graph, vertex_idx, aux) do
    index_to_vertex_map(graph) |> get_in([vertex_idx | aux])
  end

  def update_vertex(_graph, vertex_idx, _aux) when is_nil(vertex_idx) do
    nil
  end

  def update_vertex(graph, vertex_idx, vertex_info) when is_integer(vertex_idx) do
    put_in(graph, [:vertices, :index_to_vertex, vertex_idx, :opts], vertex_info)
  end

  def delete_vertex(%{vertices: vertices} = graph, vertex) do
    vertices
    |> delete_vertex_impl(vertex)
    |> then(fn vertices -> Map.put(graph, :vertices, vertices) end)
  end

  defp add_vertex_impl(
         %{
           vertex_to_index: vertex_to_index,
           index_to_vertex: index_to_vertex,
           num_vertices: num_vertices
         } = vertices,
         vertex,
         opts
       ) do
    vertex_rec = new(vertex, opts)

    if Map.has_key?(vertex_to_index, vertex_rec.vertex) do
      vertices
    else
      num_vertices = num_vertices + 1

      %{
        vertices
        | num_vertices: num_vertices,
          vertex_to_index: Map.put(vertex_to_index, vertex_rec.vertex, num_vertices),
          index_to_vertex: Map.put(index_to_vertex, num_vertices, vertex_rec)
      }
    end
  end

  defp delete_vertex_impl(
         %{
           vertex_to_index: vertex_to_index,
           index_to_vertex: index_to_vertex,
           num_vertices: num_vertices
         } = vertices,
         vertex
       ) do
    {pos, vertex_to_index} = Map.pop(vertex_to_index, vertex)
    index_to_vertex = (pos && Map.delete(index_to_vertex, pos)) || index_to_vertex
    num_vertices = (pos && num_vertices - 1) || num_vertices

    %{
      vertices
      | vertex_to_index: vertex_to_index,
        index_to_vertex: index_to_vertex,
        num_vertices: num_vertices
    }
  end

  def out_neighbors(graph, vertex, opts \\ [])

  def out_neighbors(graph, vertex, opts) when is_list(opts) do
    out_neighbors(graph, vertex, get_neighbor_finder(graph, opts, default_neighbor_finder()))
  end

  def out_neighbors(graph, vertex, neighbor_finder)
      when is_integer(vertex) and is_function(neighbor_finder, 3) do
    neighbor_finder_call(neighbor_finder, graph, vertex, :out)
  end

  def in_neighbors(graph, vertex, opts \\ [])

  def in_neighbors(graph, vertex, opts) when is_list(opts) do
    in_neighbors(graph, vertex, get_neighbor_finder(graph, opts, default_neighbor_finder()))
  end

  def in_neighbors(graph, vertex, neighbor_finder)
      when is_integer(vertex) and is_function(neighbor_finder, 3) do
    neighbor_finder_call(neighbor_finder, graph, vertex, :in)
  end

  def neighbors(graph, vertex, opts \\ [])

  def neighbors(graph, vertex, opts) when is_list(opts) do
    neighbors(graph, vertex, get_neighbor_finder(graph, opts, default_neighbor_finder()))
  end

  def neighbors(graph, vertex, neighbor_finder)
      when is_integer(vertex) and is_function(neighbor_finder, 3) do
    Iterable.concat(
      [
        in_neighbors(graph, vertex, neighbor_finder),
        out_neighbors(graph, vertex, neighbor_finder)
      ]
    )
  end

  defp neighbor_finder_call(neighbor_finder, graph, vertex, direction) do
    neighbors = neighbor_finder.(graph, vertex, direction)
    case BitGraph.get_subgraph(graph) do
      nil -> neighbors
      subgraph ->
        Filterer.new(neighbors, fn n -> Iterable.member?(subgraph, n) end)
    end
  end

  def out_degree(graph, vertex, opts \\ []) when is_integer(vertex) do
    out_neighbors(graph, vertex, opts) |> Iterable.count()
  end

  def in_degree(graph, vertex, opts \\ []) when is_integer(vertex) do
    in_neighbors(graph, vertex, opts) |> Iterable.count()
  end

  def isolated?(_graph, nil), do: false
  def isolated?(graph, vertex) when is_integer(vertex) do
    in_neighbors(graph, vertex) |> Iterable.empty?()
    && out_neighbors(graph, vertex) |> Iterable.empty?()

  end
end
