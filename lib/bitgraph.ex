defmodule BitGraph do
  @moduledoc """
  Documentation for `Bitgraph`.
  """

  @doc """

  """
  alias BitGraph.{V, E, Adjacency}

  def new(opts \\ []) do
    opts = Keyword.merge(default_opts(), opts)
    %{
      vertices: V.init_vertices(opts),
      edges: E.init_edges(opts),
      adjacency: Adjacency.init_adjacency_table(opts[:max_vertices])
    }
  end

  def copy(%{adjacency: adjacency} = graph) do
    Map.put(graph, :adjacency, Adjacency.copy(adjacency))
  end

  def default_opts() do
    [max_vertices: 1024]
  end

  def add_vertex(graph, vertex, opts \\ []) do
    graph
    |> V.add_vertex(vertex, opts)
  end

  def add_vertices(graph, vertices) do
    Enum.reduce(vertices, graph, fn
      {vertex, opts}, acc ->
        add_vertex(acc, vertex, opts)
      vertex, acc ->
        add_vertex(acc, vertex)
    end)
  end

  def delete_vertex(graph, vertex) do
    vertex_index = V.get_vertex_index(graph, vertex)
    graph
    |> E.delete_edges(vertex_index)
    |> V.delete_vertex(vertex)
  end

  def get_vertex(graph, vertex, opts \\ []) do
    vertex_index = V.get_vertex_index(graph, vertex)
    V.get_vertex(graph, vertex_index, opts)
  end

  def update_vertex(graph, vertex, opts \\ []) do
    vertex_index = V.get_vertex_index(graph, vertex)
    V.update_vertex(graph, vertex_index, opts)
  end


  def vertices(graph) do
    graph[:vertices][:index_to_vertex] |> Map.values() |> Enum.map(&(&1.vertex))
  end

  def num_vertices(graph) do
    graph[:vertices][:num_vertices]
  end

  def add_edge(graph, from, to, opts \\ []) do
    graph
    |> V.add_vertex(from, opts)
    |> V.add_vertex(to, opts)
    |> then(fn graph ->
            from_index = V.get_vertex_index(graph, from)
            to_index = V.get_vertex_index(graph, to)
            E.add_edge(graph, from_index, to_index)
            Map.update(graph, :edges, %{}, fn edges -> Map.put(edges, {from_index, to_index}, E.new(from, to, opts)) end)
    end)
  end

  def add_edges(graph, edges) do
    Enum.reduce(edges, graph, fn
      {from, to}, acc ->
        add_edge(acc, from, to)
      {from, to, opts}, acc ->
        add_edge(acc, from, to, opts)
    end)
  end

  def delete_edge(graph, from, to) do
    from_index = V.get_vertex_index(graph, from)
    to_index = V.get_vertex_index(graph, to)
    from_index && to_index &&
    (
    E.delete_edge(graph, from_index, to_index)
    Map.update(graph, :edges, %{}, fn edges -> Map.delete(edges, {from_index, to_index}) end)
    ) || graph
  end

  def get_edge(%{edges: edges} = graph, from, to) do
    Map.get(edges, {
      V.get_vertex_index(graph, from),
      V.get_vertex_index(graph, to)
      })
  end

  def edges(graph) do
    E.edges(graph)
  end

  def num_edges(graph) do
    edges(graph) |> map_size()
  end

  def edges(graph, vertex, edge_fun \\ &default_edge_info/3) do
    MapSet.union(in_edges(graph, vertex, edge_fun), out_edges(graph, vertex, edge_fun))
  end

  def in_edges(graph, vertex, edge_fun \\ &default_edge_info/3) do
    edges_impl(graph, V.get_vertex_index(graph, vertex), edge_fun, :in_edges)
  end

  def in_neighbors(graph, vertex) do
    in_edges(graph, vertex, fn from, _to, graph -> V.get_vertex(graph, from)[:vertex] end)
  end

  def out_neighbors(graph, vertex) do
    out_edges(graph, vertex, fn _from, to, graph -> V.get_vertex(graph, to)[:vertex] end)
  end

  def out_edges(graph, vertex, edge_fun \\ &default_edge_info/3) do
    edges_impl(graph, V.get_vertex_index(graph, vertex), edge_fun, :out_edges)
  end

  def in_degree(graph, vertex) do
    in_neighbors(graph, vertex) |> MapSet.size()
  end

  def out_degree(graph, vertex) do
    out_neighbors(graph, vertex) |> MapSet.size()
  end

  defp edges_impl(graph, vertex_index, edge_info_fun, direction) when is_integer(vertex_index) do
    neighbor_indices = neighbors_impl(graph, vertex_index, direction)
    Enum.reduce(neighbor_indices, MapSet.new(), fn neighbor_index, acc ->
      {from_vertex, to_vertex} = edge_vertices(vertex_index, neighbor_index, direction)
      MapSet.put(acc, edge_info_fun.(from_vertex, to_vertex, graph))
    end)
  end

  defp edges_impl(_graph, vertex_index, _edge_info_fun, _direction) when is_nil(vertex_index) do
    MapSet.new()
  end

  defp default_edge_info(from, to, %{edges: edges} = _graph) do
    Map.get(edges, {from, to})
  end

  defp neighbors_impl(graph, vertex_index, :out_edges) do
    E.out_neighbors(graph, vertex_index)
  end

  defp neighbors_impl(graph, vertex_index, :in_edges) do
    E.in_neighbors(graph, vertex_index)
  end

  defp edge_vertices(v1, v2, :out_edges) do
    {v1, v2}
  end

  defp edge_vertices(v1, v2, :in_edges) do
    {v2, v1}
  end

end
