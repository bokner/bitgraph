defmodule BitGraphTest.Algorithms.Kuhn do
  alias BitGraph.Algorithms.Matching.Kuhn
  use ExUnit.Case, async: false

  @three_vertices_instance [[1, 2], [1, 2], [1, 2, 3, 4]]
  @six_vertices_instance [
    [1, 4, 5],
    [9, 10],
    [1, 4, 5, 8, 9],
    [1, 4, 5],
    [1, 4, 5, 8, 9],
    [1, 4, 5]
  ]
  @maximum_2_instance [[1, 2, 3], [1, 2, 3]]

  @free_node_instance [
    [1],
    [1, 2],
    [1, 2, 3, 4],
    [1, 2, 4, 5]
  ]

  describe "Kuhn maximal matching" do
    test "3 vertices in left-side partition" do
      right_side_neighbors = @three_vertices_instance

      {bp_graph, left_partition} = build_bp_graph(right_side_neighbors)

      matching = Kuhn.run(bp_graph, left_partition)

      assert_matching(matching, 3)

      bp_graph2 = BitGraph.delete_edge(bp_graph, {:L, 3}, {:R, 3})

      matching2 = Kuhn.run(bp_graph2, left_partition)

      assert_matching(matching2, 3)

      bp_graph3 = BitGraph.delete_edge(bp_graph2, {:L, 3}, {:R, 4})

      ## 3 nodes in the left partition, 2 nodes in the right partition
      matching3 = Kuhn.run(bp_graph3, left_partition)

      assert_matching(matching3, 2)
    end

    test "6 vertices in left-side partition" do
      right_side_neighbors = @six_vertices_instance

      {bp_graph, left_partition} = build_bp_graph(right_side_neighbors)

      matching = Kuhn.run(bp_graph, left_partition)

      assert_matching(matching, 6)

      bp_graph2 = BitGraph.delete_edge(bp_graph, {:L, 6}, {:R, 5})

      matching2 = Kuhn.run(bp_graph2, left_partition)

      assert_matching(matching2, 6)

      bp_graph3 =
        bp_graph2
        |> BitGraph.delete_edge({:L, 1}, {:R, 5})
        |> BitGraph.delete_edge({:L, 4}, {:R, 5})

      matching3 = Kuhn.run(bp_graph3, left_partition)

      assert_matching(matching3, 5)
    end

    test "initial_matching (3 vertices)" do
      right_side_neighbors = @three_vertices_instance

      {bp_graph, left_partition} = build_bp_graph(right_side_neighbors)
      assert_matching(Kuhn.run(bp_graph, left_partition), 3)
    end

    test "initial_matching (6 vertices)" do
      right_side_neighbors = @six_vertices_instance

      {bp_graph, left_partition} = build_bp_graph(right_side_neighbors)
      # initial_matching = Kuhn.initial_matching(bp_graph, left_partition)
      # initial_matching = Kuhn.initial_matching(bp_graph, left_partition, initial_matching)

      assert_matching(Kuhn.run(bp_graph, left_partition), 6)
    end

    test "fixed matching" do
      right_side_neighbors = @six_vertices_instance

      {bp_graph, left_partition} = build_bp_graph(right_side_neighbors)

      fixed_matching = %{{:L, 1} => {:R, 5}}
      #fixed_matching = %{}
      matching = Kuhn.run(bp_graph, left_partition, fixed_matching: fixed_matching)

      assert_matching(matching, 6)

      ## Fixed matching is respected
      assert {:R, 5} = Map.get(matching.matching, {:L, 1})

      matching_no_fixed = Kuhn.run(bp_graph, left_partition)

      # Matching with nothing fixed is different
      refute {:R, 5} == Map.get(matching_no_fixed.matching, {:L, 1})


    end

    test "fixed matchings that are not in left partition will fire an exception" do
      right_side_neighbors = @maximum_2_instance
      {bp_graph, left_partition} = build_bp_graph(right_side_neighbors)
      ## There is no value 0 for any of the left-side vertices
      non_value_edge = %{{:R, 0} => {:L, 1}}

      assert catch_throw(
               {:error, {:not_in_left_partition, {:R, 0}}} =
                 Kuhn.run(bp_graph, left_partition, fixed_matching: non_value_edge)
             )

      non_variable_edge = %{{:R, 1} => {:L, 0}}

      assert catch_throw(
               {:error, {:not_in_left_partition, {:L, 0}}} =
                 Kuhn.run(bp_graph, left_partition, fixed_matching: non_variable_edge)
             )
    end

    test "required matching size" do
      right_side_neighbors = @three_vertices_instance

      {bp_graph, left_partition} = build_bp_graph(right_side_neighbors)
      refute Kuhn.run(bp_graph, left_partition, required_size: 4)
      assert Kuhn.run(bp_graph, left_partition, required_size: 3)
    end

    test "free nodes" do
      right_side_neighbors = @free_node_instance

      {bp_graph, left_partition} = build_bp_graph(right_side_neighbors)
      %{free: free_nodes, matching: matching} = Kuhn.run(bp_graph, left_partition)
      ## Free nodes belong to value graph
      assert Enum.all?(free_nodes, fn node -> BitGraph.get_vertex(bp_graph, node) end)
      ## All free nodes are in the 'right' partition
      assert MapSet.intersection(free_nodes, left_partition) |> MapSet.size() == 0
      ## Free nodes are not in matching
      refute Enum.any?(free_nodes, fn node -> node in Map.values(matching) end)
      ## For this case, there is a single free node
      assert MapSet.size(free_nodes) == 1
    end
  end

  defp build_bp_graph(right_side_neighbors) do
    left_partition = Enum.map(1..length(right_side_neighbors), fn idx -> {:L, idx} end)

    graph_input = Enum.zip(left_partition, right_side_neighbors)

    bp_graph =
      Enum.reduce(graph_input, BitGraph.new() |> BitGraph.add_vertices(left_partition), fn {ls_vertex, rs_neighbors}, g_acc ->
        edges = Enum.map(rs_neighbors, fn rsn -> {ls_vertex, {:R, rsn}} end)
        BitGraph.add_edges(g_acc, edges)
      end)

    {bp_graph, MapSet.new(left_partition)}
  end

  defp assert_matching(matching, size) do
    assert size == map_size(matching.matching)
    assert size == Map.values(matching.matching) |> Enum.uniq() |> length()
  end
end
