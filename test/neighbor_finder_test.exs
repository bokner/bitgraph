defmodule BitGraphTest.NeighborFinder do
  use ExUnit.Case

  alias BitGraph.Algorithms.Matching.Kuhn

  test "neighbor finder function" do
    ## Complete bipartite graph with left -> right edges
    graph =
      for left <- 1..3, right <- 1..3, reduce: BitGraph.new() do
        acc ->
          BitGraph.add_edge(acc, {:L, left}, {:R, right})
      end

    ## All edges are oriented from left partition to right partition - the graph
    ## is not strongly connected
    refute BitGraph.strongly_connected?(graph)
    ## The same graph with matching edges oriented from right to left partition
    ## will form the cycle

    ## We now buld the neighbor finder that intperprets
    ## edges in bipartite matching as oriented from right to left partition
    neighbor_finder_fun = build_neighbor_finder(graph)

    assert BitGraph.strongly_connected?(graph, neighbor_finder: neighbor_finder_fun)
  end

  defp build_neighbor_finder(graph) do
    %{matching: left_to_right_matching} = Kuhn.run(graph, Enum.map(1..3, fn idx -> {:L, idx} end))

    right_to_left_matching = Map.new(left_to_right_matching, fn {l, r} -> {r, l} end)

    fn graph, vertex_index, direction ->
      vertex = BitGraph.V.get_vertex(graph, vertex_index)

      BitGraph.E.default_neighbor_finder().(graph, vertex_index, direction)
      |> reverse_matching_edges(
        graph,
        vertex,
        left_to_right_matching,
        right_to_left_matching,
        direction
      )
    end
  end

  defp reverse_matching_edges(
         _neighbors,
         graph,
         {:L, _vertex_index} = left_vertex,
         left_to_right_matching,
         _right_to_left_matching,
         :in
       ) do
    case get_matching_index(graph, left_to_right_matching, left_vertex) do
      nil ->
        MapSet.new()

      right_vertex ->
        MapSet.new([right_vertex])
    end
  end

  defp reverse_matching_edges(
         neighbors,
         graph,
         {:L, _vertex_index} = left_vertex,
         left_to_right_matching,
         _right_to_left_matching,
         :out
       ) do
    MapSet.delete(neighbors, get_matching_index(graph, left_to_right_matching, left_vertex))
  end

  defp reverse_matching_edges(
         neighbors,
         graph,
         {:R, _vertex_index} = right_vertex,
         _left_to_right_matching,
         right_to_left_matching,
         :in
       ) do
    MapSet.delete(neighbors, get_matching_index(graph, right_to_left_matching, right_vertex))
  end

  defp reverse_matching_edges(
         _neighbors,
         graph,
         {:R, _vertex_index} = right_vertex,
         _left_to_right_matching,
         right_to_left_matching,
         :out
       ) do
    case get_matching_index(graph, right_to_left_matching, right_vertex) do
      nil ->
        MapSet.new()

      left_vertex ->
        MapSet.new([left_vertex])
    end
  end

  defp get_matching_index(graph, matching, vertex) do
    case Map.get(matching, vertex) do
      nil ->
        nil

      matching_vertex ->
        BitGraph.V.get_vertex_index(graph, matching_vertex)
    end
  end
end
