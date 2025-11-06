defmodule BitGraphTest.NeighborFinder do
  use ExUnit.Case

  alias BitGraph.Algorithm.Matching.Kuhn

  test "neighbor_finder: neighbors and edges" do
    ## Buid bipartite graph with edges oriented from left partition to right partition
    partition_size = 3

    graph =
      Enum.reduce(1..partition_size, BitGraph.new(allocate_adjacency_table?: false), fn idx,
                                                                                        g_acc ->
        BitGraph.add_vertex(g_acc, {:L, idx})
      end)
      |> then(fn g ->
        Enum.reduce(1..partition_size, g, fn idx, g_acc ->
          BitGraph.add_vertex(g_acc, {:R, idx})
        end)
      end)

    ## Note that we have requested not to allocate adjacency table.
    %{adjacency: %{bit_vector: bit_vector}} = graph
    refute bit_vector

    virtual_graph = BitGraph.set_neighbor_finder(graph, bipartite_neighbor_finder(partition_size))

    ## neighbors and degrees
    assert Enum.all?(1..partition_size, fn idx ->
             BitGraph.out_neighbors(virtual_graph, {:L, idx}) ==
               MapSet.new(1..partition_size, fn idx -> {:R, idx} end) &&
               BitGraph.out_degree(virtual_graph, {:L, idx}) == partition_size &&
               BitGraph.in_neighbors(virtual_graph, {:R, idx}) ==
                 MapSet.new(1..partition_size, fn idx -> {:L, idx} end) &&
               BitGraph.in_degree(virtual_graph, {:R, idx}) == partition_size &&
               Enum.empty?(BitGraph.out_neighbors(virtual_graph, {:R, idx})) &&
               BitGraph.out_degree(virtual_graph, {:R, idx}) == 0 &&
               Enum.empty?(BitGraph.in_neighbors(virtual_graph, {:L, idx})) &&
               BitGraph.in_degree(virtual_graph, {:L, idx}) == 0
           end)

    ## edges
    assert Enum.all?(1..partition_size, fn idx ->
             BitGraph.out_edges(virtual_graph, {:L, idx}) ==
               MapSet.new((partition_size + 1)..(partition_size * 2), fn neighbor_idx ->
                 BitGraph.E.new(idx, neighbor_idx)
               end) &&
               BitGraph.in_edges(virtual_graph, {:L, idx}) == MapSet.new() &&
               BitGraph.in_edges(virtual_graph, {:R, idx}) ==
                 MapSet.new(1..partition_size, fn neighbor_idx ->
                   BitGraph.E.new(neighbor_idx, idx + partition_size)
                 end) &&
               BitGraph.out_edges(virtual_graph, {:R, idx}) == MapSet.new()
           end)
  end

  test "neighbor finder on DFS" do
    ## Build complete bipartite graph
    partition_size = 3

    graph =
      for left <- 1..partition_size, right <- 1..partition_size, reduce: BitGraph.new() do
        acc ->
          BitGraph.add_edge(acc, {:L, left}, {:R, right})
      end

    ## All edges are oriented from left partition to right partition - the graph
    ## is not strongly connected
    refute BitGraph.strongly_connected?(graph)
    ## The same graph with matching edges oriented from right to left partition
    ## will form the cycle

    ## We now build the neighbor finder that intperprets
    ## edges in bipartite matching as oriented from right to left partition
    neighbor_finder_fun = matching_neighbor_finder(graph)

    assert BitGraph.strongly_connected?(graph, neighbor_finder: neighbor_finder_fun)
  end

  test "Iterable neighbor finder on DFS" do
    ## Build complete bipartite graph with left -> right edges
    partition_size = 3

    graph =
      for left <- 1..partition_size, right <- 1..partition_size, reduce: BitGraph.new() do
        acc ->
          BitGraph.add_edge(acc, {:L, left}, {:R, right})
      end

    neighbor_iterator = iterating_neighbor_finder(matching_neighbor_finder(graph))

    ## Same as in the previous test, but with iterable neighbor finder.
    assert BitGraph.strongly_connected?(graph, neighbor_finder: neighbor_iterator)
  end

  defp bipartite_neighbor_finder(partition_size) do
    left_partition = 1..partition_size
    right_partition = (partition_size + 1)..(2 * partition_size)

    fn _graph, vertex_index, direction ->
      cond do
        vertex_index in left_partition && direction == :out ->
          MapSet.new(right_partition)

        vertex_index in left_partition && direction == :in ->
          MapSet.new()

        vertex_index in right_partition && direction == :out ->
          MapSet.new()

        vertex_index in right_partition && direction == :in ->
          MapSet.new(left_partition)
      end
    end
  end

  defp matching_neighbor_finder(graph) do
    ## Collect left partition vertices
    left_partition = Enum.filter(BitGraph.vertices(graph), fn v -> elem(v, 0) == :L end)
    ## Convert to vertex-index form
    vertex_index_opts = Kuhn.preprocess(graph, left_partition: left_partition)

    result =
      Kuhn.run(
        graph,
        vertex_index_opts
        # Enum.flat_map(BitGraph.vertices(graph),
        #   fn {:L, _} = vertex -> [BitGraph.V.get_vertex_index(graph, vertex)]
        #      {:R, _} -> []
        # end)
      )

    ## Kuhn algorithm returns data based on vertex indices
    ## We transform to 'vertex' form, using the helper
    %{matching: left_to_right_matching} = Kuhn.postprocess(graph, result)

    right_to_left_matching = Map.new(left_to_right_matching, fn {l, r} -> {r, l} end)

    fn graph, vertex_index, direction ->
      vertex = BitGraph.V.get_vertex(graph, vertex_index)

      BitGraph.Neighbor.default_neighbor_finder().(graph, vertex_index, direction)
      |> reverse_matching_edges(
        graph,
        vertex,
        left_to_right_matching,
        right_to_left_matching,
        direction
      )
    end
  end

  defp iterating_neighbor_finder(neighbor_finder) do
    fn graph, vertex_index, direction ->
      neighbor_finder.(graph, vertex_index, direction)
      |> Iter.IntoIterable.into_iterable()
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
