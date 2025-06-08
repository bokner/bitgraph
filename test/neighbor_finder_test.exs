defmodule BitGraphTest.NeighborFinder do
  use ExUnit.Case

  alias BitGraph.Algorithms.Matching.Kuhn

  test "neighbor finder function" do
    graph =
    ## Complete bipartite graph with left -> right edges
    for left <- 1..3, right <- 1..3, reduce: BitGraph.new() do
      acc ->
      BitGraph.add_edge(acc, {:L, left}, {:R, right})
    end

    refute BitGraph.strongly_connected?(graph)

    %{matching: left_to_right_matching} = Kuhn.run(graph, Enum.map(1..3, fn idx -> {:L, idx} end))
    ## Inverse matching : right => left map
    right_to_left_matching = Map.new(matching, fn {l, r} -> {r, l} end)

    neighbor_finder_fun =
      fn graph, vertex_index, direction ->
        vertex = BitGraph.get_vertex(graph, vertex_index)
        E.default_neighbor_finder(graph, vertex_index, direction)
        |> reverse_matching_edges(graph, vertex, left_to_right_matching, right_to_left_matching, direction)
      end
    end

    defp reverse_matching_edges(graph, {:L, vertex_index} = left_vertex, neighbors, left_to_right_matching, _right_to_left_matching, :in) do
      case get_matching_index(graph, left_to_right_matching, left_vertex) do
        nil -> MapSet.new()
        right_vertex ->
          MapSet.new([right_vertex])
      end
    end

    defp reverse_matching_edges(graph, {:L, vertex_index} = left_vertex, neighbors, left_to_right_matching, _right_to_left_matching, :out) do
      MapSet.delete(neighbors, get_matching_index(graph, left_to_right_matching, left_vertex))
    end


    defp reverse_matching_edges(graph, {:R, vertex_index} = right_vertex, neighbors, _left_to_right_matching, right_to_left_matching, :in) do
      MapSet.delete(neighbors, get_matching_index(graph, right_to_left_matching, right_vertex))
    end

    defp reverse_matching_edges(graph, {:R, vertex_index} = right_vertex, neighbors, _left_to_right_matching, right_to_left_matching, :out) do
      case get_matching_index(graph, right_to_left_matching, right_vertex) do
        nil -> MapSet.new()
        left_vertex ->
          MapSet.new([left_vertex])
      end

    end

    defp get_matching_index(graph, vertex, matching) do
      case Map.get(matching, vertex) do
        nil -> nil
        matching_vertex ->
          BitGraph.get_vertex_index(graph, matching_vertex)
      end
    end

end
