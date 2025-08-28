defmodule BitGraph do
  @moduledoc """
  Documentation for `BitGraph`.
  """

  @doc """

  """

  @type t :: map()

  alias BitGraph.{V, E, Adjacency, Neighbor}
  alias Iter.{Iterable, Iterable.Mapper}
  import BitGraph.Common

  def new(opts \\ []) do
    opts = Keyword.merge(default_opts(), opts)
    %{
      opts: opts,
      vertices: V.init_vertices(opts),
      edges: E.init_edges(opts),
      adjacency: Adjacency.init_adjacency_table(opts),
      owner: self()
    }
  end

  def copy(%{adjacency: adjacency} = graph) do
    Map.put(graph, :adjacency, Adjacency.copy(adjacency, graph.edges))
  end

  @doc """
  An induced subgraph on `subgraph_vertices`
  """
  def subgraph(graph, subgraph_vertices, mode \\ :detached)

  ## Makes a 'detached' subgraph that only contains
  ## subset of vertices and edges between them.
  ##
  def subgraph(graph, subgraph_vertices, :detached) do
    Enum.reduce(BitGraph.vertices(graph), copy(graph),
      fn existing_vertex, acc ->
        if !Iterable.member?(subgraph_vertices, existing_vertex) do
          BitGraph.delete_vertex(acc, existing_vertex)
        else
          acc
        end
      end
    )
  end

  ## Maps the graph onto a subgraph.
  ## The vertex implementation will use the subgraph option
  ## to filter vertices accordingly.
  ## The graph structure will not be modified.
  def subgraph(graph, subgraph_vertices, :mapped) do
    Map.put(graph, :subgraph,
    ## :subgraph keeps the set of vertex indices in the form of iterator
    Enum.reduce(subgraph_vertices, MapSet.new(), fn vertex, acc ->
      case V.get_vertex_index(graph, vertex) do
        nil -> acc
        idx -> MapSet.put(acc, idx)
      end
    end)
    )
  end

  def strong_components(graph, opts \\ []) do
    graph
    |> update_opts(opts)
    |> BitGraph.Algorithms.strong_components(opts)
    |> Enum.map(fn component ->
      MapSet.new(component, fn vertex_idx -> BitGraph.V.get_vertex(graph, vertex_idx) end)
    end)
  end

  def strongly_connected?(graph, opts \\ []) do
    BitGraph.Algorithms.strongly_connected?(graph, opts)
  end

  def default_opts() do
    [
      max_vertices: 1024
    ]
  end

  defp core_opts_names() do
    [:neighbor_finder]
  end

  def get_opts(graph) do
    graph[:opts]
  end

  def update_opts(graph, []) do
    graph
  end

  def update_opts(graph, opts) do
    Map.update!(graph, :opts,
      fn current_opts ->
        Keyword.merge(current_opts,
        Keyword.take(opts, core_opts_names()))
      end)
  end

  def get_opt(graph, option) do
    get_opts(graph)[option]
  end

  def set_opt(graph, option, value) do
    put_in(graph, [:opts, option], value)
  end

  def set_neighbor_finder(graph, neighbor_finder) do
    set_opt(graph, :neighbor_finder, neighbor_finder)
  end

  def get_neighbor_finder(graph) do
    Neighbor.get_neighbor_finder(graph)
  end

  def get_subgraph(graph) do
    graph[:subgraph]
  end

  def add_vertex(graph, vertex, opts \\ []) do
    graph
    |> V.add_vertex(vertex, opts)
  end

  def add_vertices(graph, vertices) do
    Enum.reduce(vertices, graph, fn
      {vertex, opts}, acc when is_list(opts) ->
        add_vertex(acc, vertex, opts)
      vertex, acc ->
        add_vertex(acc, vertex)
    end)
  end

  def isolated_vertex?(graph, vertex) do
    vertex && V.isolated?(graph, V.get_vertex_index(graph, vertex))
  end

  def delete_vertex(graph, vertex) do
    case V.get_vertex_index(graph, vertex) do
      nil -> graph
      vertex_index ->
        graph
        |> E.delete_edges(vertex_index)
        |> V.delete_vertex(vertex)
      end
  end

  def get_vertex(graph, vertex, opts \\ []) do
    vertex_index = V.get_vertex_index(graph, vertex)
    V.get_vertex(graph, vertex_index, opts)
  end

  def update_vertex(graph, vertex, opts \\ []) do
    vertex_index = V.get_vertex_index(graph, vertex)
    V.update_vertex(graph, vertex_index, opts)
  end


  def vertices(graph, mapper \\ &(&1.vertex)) do
    V.vertices(graph, mapper)
  end

  def vertex_indices(graph) do
    V.vertex_indices(graph)
  end

  def max_index(graph) do
    vertex_indices(graph) |> Enum.max()
  end

  def num_vertices(graph) do
    V.num_vertices(graph)
  end

  def add_edge(graph, {_edge_key, %E{} = edge}) do
    add_edge(graph, edge)
  end

  def add_edge(graph, %E{from: from, to: to, opts: opts}) do
    add_edge(graph, from, to, opts)
  end

  def add_edge(graph, from, to, opts \\ []) do
    graph
    |> V.add_vertex(from, opts)
    |> V.add_vertex(to, opts)
    |> then(fn graph ->
            from_index = V.get_vertex_index(graph, from)
            to_index = V.get_vertex_index(graph, to)
            E.add_edge(graph, from_index, to_index)
            Map.update(graph, :edges, %{},
              fn edges ->
                Map.put(edges, {from_index, to_index}, E.new(from, to, opts))
              end)
    end)
  end

  def add_edges(graph, edges) do
    Enum.reduce(edges, graph, fn
      {from, to}, acc ->
        add_edge(acc, from, to)
      {from, to, opts}, acc ->
        add_edge(acc, from, to, opts)
      %E{} = edge, acc ->
        add_edge(acc, edge)
    end)
  end

  def delete_edge(graph, {_edge_key, %E{} = edge}) do
    delete_edge(graph, edge)
  end

  def delete_edge(graph, %E{from: from, to: to} = _edge) do
    delete_edge(graph, from, to)
  end

  def delete_edge(graph, from, to) do
    from_index = V.get_vertex_index(graph, from)
    to_index = V.get_vertex_index(graph, to)
    from_index && to_index &&
    E.delete_edge(graph, from_index, to_index)
    || graph
  end

  def delete_edges(graph, edges) do
    Enum.reduce(edges, graph, fn {from, to}, acc ->
      delete_edge(acc, from, to)
    end)
  end


  def get_edge(graph, from, to) do
    E.get_edge(graph,
      V.get_vertex_index(graph, from),
      V.get_vertex_index(graph, to)
    )
  end

  def edges(graph) do
    E.edges(graph)
  end

  def num_edges(graph) do
    E.edges(graph) |> MapSet.size()
  end

  def edges(graph, vertex, edge_fun \\ &default_edge_info/3, opts \\ []) do
    MapSet.union(in_edges(graph, vertex, edge_fun, opts), out_edges(graph, vertex, edge_fun, opts))
  end

  def in_edges(graph, vertex, edge_fun \\ &default_edge_info/3, opts \\ []) do
    graph = update_opts(graph, opts)
    edges_impl(graph, V.get_vertex_index(graph, vertex), edge_fun, :in, opts)
  end

  def out_edges(graph, vertex, edge_fun \\ &default_edge_info/3, opts \\ []) do
    graph = update_opts(graph, opts)
    edges_impl(graph, V.get_vertex_index(graph, vertex), edge_fun, :out, opts)
  end

  def in_neighbors(graph, vertex, opts \\ []) do
    graph = update_opts(graph, opts)

    case V.get_vertex_index(graph, vertex) do
      nil -> MapSet.new()
      vertex_index -> V.in_neighbors(graph, vertex_index)
    end
    |> shape(graph, vertex, opts)
  end

  def out_neighbors(graph, vertex, opts \\ []) do
    graph = update_opts(graph, opts)

    case V.get_vertex_index(graph, vertex) do
      nil -> MapSet.new()
      vertex_index -> V.out_neighbors(graph, vertex_index)
    end
    |> shape(graph, vertex, opts)
  end

  defp shape(neighbors, graph, vertex, opts) do
    shape = Keyword.get(opts, :shape, :set)
    transform_neighbors(graph, vertex, neighbors, shape)
  end

  ## Neighbors as an enum of vertices.
  def transform_neighbors(graph, vertex, neighbors, :set) do
    transform_neighbors(graph, vertex, neighbors, :iterator)
    |> iterate(MapSet.new(), fn neighbor, acc -> {:cont, MapSet.put(acc, neighbor)} end)
  end

  ## Neighbors as an iterator of vertices
  def transform_neighbors(graph, _vertex, neighbors, :iterator) do
    Mapper.new(neighbors, fn vertex_index ->
       V.get_vertex(graph, vertex_index)
    end)

  end

  ## Neighbors
  def transform_neighbors(graph, vertex, neighbors, transform_fun) when is_function(transform_fun, 3) do
    transform_fun.(graph, vertex, neighbors)
  end

  def neighbors(graph, vertex, opts \\ []) do
    Iterable.concat(
    [out_neighbors(graph, vertex, opts), in_neighbors(graph, vertex, opts)]
    )
  end

  def in_degree(graph, vertex, opts \\ []) do
    in_neighbors(graph, vertex, opts) |> MapSet.size()
  end

  def degree(graph, vertex, opts \\ []) do
    in_degree(graph, vertex, opts) + out_degree(graph, vertex, opts)
  end

  def out_degree(graph, vertex, opts \\ []) do
    out_neighbors(graph, vertex, opts) |> MapSet.size()
  end

  ## Show the graph (intended for debugging)
  def show_graph(graph, context \\ nil) do
    %{
      context: context,
      vartices: BitGraph.vertices(graph) |> Iterable.to_list(),
      edges:
        BitGraph.E.edges(graph)
        |> Iterable.map(fn %{from: from_index, to: to_index} ->
          {
            BitGraph.V.get_vertex(graph, from_index),
            BitGraph.V.get_vertex(graph, to_index)
          }
        end)
        |> Iterable.to_list()
        |> Enum.group_by(fn {from, _to} -> from end, fn {_from, to} -> to end)
    }
  end

  defp edges_impl(graph, vertex_index, edge_info_fun, direction, _opts) when is_integer(vertex_index) do
    edges = direction == :in && E.in_edges(graph, vertex_index) || E.out_edges(graph, vertex_index)
    iterate(edges, MapSet.new(), fn %E{from: from, to: to}, acc ->
      {:cont,
        case edge_info_fun.(from, to, graph) do
         nil -> acc
         edge_info -> MapSet.put(acc, edge_info)
        end
      }
    end)
  end

  defp edges_impl(_graph, vertex_index, _edge_info_fun, _direction, _opts) when is_nil(vertex_index) do
    MapSet.new()
  end

  defp default_edge_info(from, to, %{edges: edges} = _graph) when is_integer(from) and is_integer(to) do
    Map.get(edges, {from, to}, E.new(from, to))
  end

  defp default_edge_info(from, to, graph) do
    default_edge_info(V.get_vertex_index(graph, from), V.get_vertex_index(graph, to), graph)
  end

end
