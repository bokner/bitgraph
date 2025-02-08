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

  def vertices(graph) do
    graph[:vertices][:pos_to_vertex] |> Map.values() |> Enum.map(&(&1.vertex))
  end

  def add_edge(graph, from, to, opts \\ []) do
    graph
    |> V.add_vertex(from, opts)
    |> V.add_vertex(to, opts)
    |> then(fn graph ->
            from_pos = Map.get(graph[:vertices][:id_to_pos], from)
            to_pos = Map.get(graph[:vertices][:id_to_pos], to)
            E.add_edge(graph, from_pos, to_pos)
            Map.update(graph, :edges, %{}, fn edges -> Map.put(edges, {from, to}, E.new(from, to, opts)) end)
    end)
  end

  def edges(graph, vertex, edge_fun \\ &default_edge_info/3) do
    MapSet.union(in_edges(graph, vertex, edge_fun), out_edges(graph, vertex, edge_fun))
  end

  def in_edges(graph, vertex, edge_fun \\ &default_edge_info/3) do
    edges_impl(graph, get_vertex_pos(graph, vertex), edge_fun, :in_edges)
  end

  def out_edges(graph, vertex, edge_fun \\ &default_edge_info/3) do
    edges_impl(graph, get_vertex_pos(graph, vertex), edge_fun, :out_edges)
  end

  defp edges_impl(%{adjacency: adjacency} = graph, vertex_pos, edge_info_fun, direction) when is_integer(vertex_pos) do
    neighbor_positions = neighbors(vertex_pos, adjacency, direction)
    Enum.reduce(neighbor_positions, MapSet.new(), fn neighbor_pos, acc ->
      {from_vertex, to_vertex} = edge_vertices(vertex_pos, neighbor_pos, direction)
      MapSet.put(acc, edge_info_fun.(from_vertex, to_vertex, graph))
    end)
  end

  defp default_edge_info(from, to, %{edges: edges, vertices: %{pos_to_vertex: pos_to_vertex_map}} = _graph) do
    Map.get(edges, {Map.get(pos_to_vertex_map, from)[:vertex], Map.get(pos_to_vertex_map, to)[:vertex]})
  end

  defp neighbors(vertex_pos, adjacency_table, :out_edges) do
    Adjacency.row(adjacency_table, vertex_pos)
  end

  defp neighbors(vertex_pos, adjacency_table, :in_edges) do
    Adjacency.column(adjacency_table, vertex_pos)
  end

  defp edge_vertices(v1, v2, :out_edges) do
    {v1, v2}
  end

  defp edge_vertices(v1, v2, :in_edges) do
    {v2, v1}
  end

  defp get_vertex_pos(graph, vertex) do
    Map.get(graph[:vertices][:id_to_pos], vertex)
  end
end
