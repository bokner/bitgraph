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

  defp index_to_vertex_impl(graph) do
    map = graph[:vertices][:index_to_vertex]
    subgraph = BitGraph.get_subgraph(graph)
    if subgraph do
      Enum.reduce(subgraph, Map.new(),
        fn vertex_idx, acc ->
          case Map.get(map, vertex_idx) do
            nil -> acc
            vertex -> Map.put(acc, vertex_idx, vertex)
          end
        end)
    else
      map
    end
  end

  defp vertex_to_index_impl(graph) do
    graph[:vertices][:vertex_to_index]
  end

  def vertices(graph, mapper \\ &(&1.vertex)) do
    graph
    |> index_to_vertex_impl()
    |> MapSet.new(fn {_idx, vertex} -> mapper.(vertex) end)
  end

  def vertex_indices(graph) do
    index_to_vertex_impl(graph) |> Map.keys()
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
    case Map.get(vertex_to_index_impl(graph), vertex) do
      nil -> nil
      idx ->
        case BitGraph.get_subgraph(graph) do
          nil -> idx
          subgraph -> if Iterable.member?(subgraph, idx), do: idx
        end
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
    index_to_vertex_impl(graph) |> get_in([vertex_idx | aux])
  end

  def get_vertex(graph, vertex_label, aux) do
    vertex_to_index_impl(graph)
    |> Map.get(vertex_label)
    |> then(fn vertex_idx -> if vertex_idx, do: get_vertex(graph, vertex_idx, aux) end)
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
           vertex_to_index: vertex_to_index_map,
           index_to_vertex: index_to_vertex_map,
           num_vertices: num_vertices
         } = vertices,
         vertex,
         opts
       ) do
    vertex_rec = new(vertex, opts)

    if Map.has_key?(vertex_to_index_map, vertex_rec.vertex) do
      vertices
    else
      num_vertices = num_vertices + 1

      %{
        vertices
        | num_vertices: num_vertices,
          vertex_to_index: Map.put(vertex_to_index_map, vertex_rec.vertex, num_vertices),
          index_to_vertex: Map.put(index_to_vertex_map, num_vertices, vertex_rec)
      }
    end
  end

  defp delete_vertex_impl(
         %{
           vertex_to_index: vertex_to_index_map,
           index_to_vertex: index_to_vertex_map,
           num_vertices: num_vertices
         } = vertices,
         vertex
       ) do
    {pos, vertex_to_index_map} = Map.pop(vertex_to_index_map, vertex)
    index_to_vertex_map = (pos && Map.delete(index_to_vertex_map, pos)) || index_to_vertex_map
    num_vertices = (pos && num_vertices - 1) || num_vertices

    %{
      vertices
      | vertex_to_index: vertex_to_index_map,
        index_to_vertex: index_to_vertex_map,
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
    subgraph = BitGraph.get_subgraph(graph)
    neighbors = neighbor_finder.(graph, vertex, direction)
    subgraph && Filterer.new(neighbors, fn n -> Iterable.member?(subgraph, n) end) || neighbors
  end

  def out_degree(graph, vertex, opts \\ []) when is_integer(vertex) do
    out_neighbors(graph, vertex, opts) |> Iterable.count()
  end

  def in_degree(graph, vertex, opts \\ []) when is_integer(vertex) do
    in_neighbors(graph, vertex, opts) |> Iterable.count()
  end

  def isolated?(_graph, nil), do: false
  def isolated?(graph, vertex) when is_integer(vertex) do
    in_neighbors(graph, vertex) |> Iterable.next() == :done
    && out_neighbors(graph, vertex) |> Iterable.next() == :done

  end
end
