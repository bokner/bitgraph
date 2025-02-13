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
      adjacency: Adjacency.init_adjacency_table(opts[:max_vertices])}
  end

  def default_opts() do
    [max_vertices: 1024]
  end

  def add_vertex(graph, vertex, opts \\ []) do
    graph
    |> V.add_vertex(vertex, opts)
  end

  def delete_vertex(graph, vertex) do
    vertex_index = get_vertex_index(graph, vertex)
    graph
    |> E.delete_edges(vertex_index)
    |> V.delete_vertex(vertex)
  end

  def vertices(graph) do
    graph[:vertices][:index_to_vertex] |> Map.values() |> Enum.map(&(&1.vertex))
  end

  def add_edge(graph, from, to, opts \\ []) do
    graph
    |> V.add_vertex(from, opts)
    |> V.add_vertex(to, opts)
    |> then(fn graph ->
            from_index = get_vertex_index(graph, from)
            to_index = get_vertex_index(graph, to)
            E.add_edge(graph, from_index, to_index)
            Map.update(graph, :edges, %{}, fn edges -> Map.put(edges, {from_index, to_index}, E.new(from, to, opts)) end)
    end)
  end

  def delete_edge(graph, from, to) do
    from_index = get_vertex_index(graph, from)
    to_index = get_vertex_index(graph, to)
    from_index && to_index &&
    (
    E.delete_edge(graph, from_index, to_index)
    Map.update(graph, :edges, %{}, fn edges -> Map.delete(edges, {from_index, to_index}) end)
    ) || graph
  end

  def edges(graph, vertex, edge_fun \\ &default_edge_info/3) do
    MapSet.union(in_edges(graph, vertex, edge_fun), out_edges(graph, vertex, edge_fun))
  end

  def in_edges(graph, vertex, edge_fun \\ &default_edge_info/3) do
    edges_impl(graph, get_vertex_index(graph, vertex), edge_fun, :in_edges)
  end

  def out_edges(graph, vertex, edge_fun \\ &default_edge_info/3) do
    edges_impl(graph, get_vertex_index(graph, vertex), edge_fun, :out_edges)
  end

  defp edges_impl(%{adjacency: adjacency} = graph, vertex_index, edge_info_fun, direction) when is_integer(vertex_index) do
    neighbor_indices = neighbors(vertex_index, adjacency, direction)
    Enum.reduce(neighbor_indices, MapSet.new(), fn neighbor_index, acc ->
      {from_vertex, to_vertex} = edge_vertices(vertex_index, neighbor_index, direction)
      MapSet.put(acc, edge_info_fun.(from_vertex, to_vertex, graph))
    end)
  end

  defp default_edge_info(from, to, %{edges: edges} = _graph) do
    Map.get(edges, {from, to})
  end

  defp neighbors(vertex_index, adjacency_table, :out_edges) do
    Adjacency.row(adjacency_table, vertex_index)
  end

  defp neighbors(vertex_index, adjacency_table, :in_edges) do
    Adjacency.column(adjacency_table, vertex_index)
  end

  defp edge_vertices(v1, v2, :out_edges) do
    {v1, v2}
  end

  defp edge_vertices(v1, v2, :in_edges) do
    {v2, v1}
  end

  def get_vertex_index(graph, vertex) do
    Map.get(graph[:vertices][:id_to_index], vertex)
  end
end
