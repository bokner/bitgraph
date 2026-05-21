defmodule BitGraphTest.Algorithm do
  use ExUnit.Case

  alias BitGraph.Common
  alias BitGraph.Algorithm
  alias BitGraph.V

  test "Topsort for DAG" do
    edges = [
      {"2", "1"},
      {"2", "0"},
      {"2", "3"},
      {"3", "0"},
      {"3", "4"},
      {"1", "5"},
      {"4", "5"},
      {"0", "5"}
    ]

    graph =
      BitGraph.new() |> BitGraph.add_edges(edges)

    topsort_result =
      graph
      |> Algorithm.topsort()
      |> then(fn indices -> Common.vertex_indices_to_ids(graph, indices) end)

    assert Enum.all?(
             edges,
             fn {from, to} ->
               Enum.find_index(topsort_result, fn val -> val == from end) <
                 Enum.find_index(topsort_result, fn val -> val == to end)
             end
           )
  end

  test "Topsort and acyclicity for graphs with/without cycles" do
    cycle = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:c, :a}, {:b, :c}])
    refute Algorithm.acyclic?(cycle)
    refute Algorithm.topsort(cycle)
    bull = BitGraph.add_edges(cycle, [{:a, :e}, {:f, :b}])
    refute Algorithm.acyclic?(bull)
    refute Algorithm.topsort(bull)
    star = BitGraph.delete_edge(bull, :b, :c)
    assert Algorithm.acyclic?(star)
    assert Algorithm.topsort(star)
  end

  test "acyclic?" do
    graph1 = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:a, :c}, {:b, :c}])
    assert Algorithm.acyclic?(graph1)

    graph2 = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:c, :a}, {:b, :c}])
    refute Algorithm.acyclic?(graph2)

    graph3 =
      BitGraph.new()
      |> BitGraph.add_edges([
        {"2", "1"},
        {"2", "0"},
        {"2", "3"},
        {"3", "0"},
        {"3", "4"},
        {"1", "5"},
        {"4", "5"},
        {"0", "5"}
      ])

    assert Algorithm.acyclic?(graph3)
  end

  test "get_cycle" do
    ## Acyclic graph
    graph1 = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:a, :c}, {:b, :c}])

    refute Enum.any?(
             BitGraph.vertex_indices(graph1),
             fn v_idx -> Algorithm.get_cycle(graph1, v_idx) end
           )

    ## Cyclic triangle
    graph2 = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:c, :a}, {:b, :c}])
    ## For every starting vertex, there is a cycle of length 3
    assert Enum.all?(
             BitGraph.vertex_indices(graph2),
             fn v_idx ->
               Algorithm.get_cycle(graph2, v_idx) |> MapSet.new() |> MapSet.size() == 3
             end
           )

    ## Bigger graph
    edges = [
      {:a, :b},
      {:b, :c},
      {:b, :e},
      {:b, :f},
      {:c, :d},
      {:c, :g},
      {:d, :c},
      {:d, :h},
      {:e, :a},
      {:e, :f},
      {:f, :g},
      {:g, :f},
      {:i, :f},
      {:h, :d},
      {:h, :g}
    ]

    wiki_graph = BitGraph.new() |> BitGraph.add_edges(edges)
    ## No cycle for edge with a single neighbor
    refute Algorithm.get_cycle(wiki_graph, V.get_vertex_index(wiki_graph, :i))

    assert Enum.all?(
             [:a, :b, :c, :d, :e, :f, :g],
             fn v ->
               v_idx = V.get_vertex_index(wiki_graph, v)

               Common.cycle?(
                 wiki_graph,
                 Algorithm.get_cycle(wiki_graph, v_idx)
               )
             end
           )
  end

  test "components" do
    edges = [
      # component 1
      {:a, :b},
      {:a, :c},
      {:b, :c},
      # component 2
      {:d, :e},
      {:d, :f},
      {:e, :f}
    ]

    graph = BitGraph.new() |> BitGraph.add_edges(edges)
    components = Algorithm.components(graph)
    assert length(components) == 2

    assert Enum.sort([MapSet.new([1, 2, 3]), MapSet.new([4, 5, 6])]) ==
             Enum.sort(components)

    single_component = BitGraph.add_edge(graph, :c, :f)
    assert length(Algorithm.components(single_component)) == 1
  end

  test "bipartite matching" do
    ## Basic test for front API
    range = 1..3
    left_partition_indices = Enum.to_list(range)
    ## Build complete bipartite graph
    left_partition = Enum.map(left_partition_indices, fn idx -> {:L, idx} end)

    graph =
      BitGraph.new()
      |> BitGraph.add_vertices(left_partition)
      |> then(fn graph ->
        Enum.reduce(range, graph, fn left_vertex, acc ->
          Enum.reduce(range, acc, fn right_vertex, acc2 ->
            BitGraph.add_edge(acc2, {:L, left_vertex}, {:R, right_vertex})
          end)
        end)
      end)

    %{matching: matching} = BitGraph.bipartite_matching(graph, left_partition: left_partition)
    assert Map.keys(matching) |> Enum.sort() == left_partition |> Enum.sort()
    assert Map.values(matching) |> Enum.uniq() |> length() == Range.size(range)

    ## Same, but only run 'raw' algorithm.
    ## This means we have to pass left partition as a list of vertex indices
    %{matching: matching} =
      BitGraph.Algorithm.bipartite_matching(graph, left_partition: Enum.to_list(range))

    assert Map.keys(matching) |> Enum.sort() == left_partition_indices
    ## By construction of the graph, left partition indices follow right partition indices.
    assert Enum.all?(Map.values(matching), fn l_idx -> l_idx in 4..6 end)
  end
end
