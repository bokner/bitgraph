defmodule BitGraphTest.Algorithms do
  use ExUnit.Case

  alias BitGraph.Common
  alias BitGraph.Algorithms
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
      BitGraph.new() |> BitGraph.add_edges(
        edges
      )

    topsort_result =
      graph
      |> Algorithms.topsort()
      |> then(fn indices -> Common.vertex_indices_to_ids(graph, indices) end)
    assert Enum.all?(edges,
        fn {from, to} ->
          Enum.find_index(topsort_result, fn val -> val == from end)
          < Enum.find_index(topsort_result, fn val -> val == to end)
        end)
  end

  test "Topsort and acyclicity for graphs with/without cycles" do
    cycle = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:c, :a}, {:b, :c}])
    refute Algorithms.acyclic?(cycle)
    refute Algorithms.topsort(cycle)
    bull = BitGraph.add_edges(cycle, [{:a, :e}, {:f, :b}])
    refute Algorithms.acyclic?(bull)
    refute Algorithms.topsort(bull)
    star = BitGraph.delete_edge(bull, :b, :c)
    assert Algorithms.acyclic?(star)
    assert Algorithms.topsort(star)
  end

  test "SCC (Kosaraju) " do
    ## Example:
    ## https://en.wikipedia.org/wiki/Strongly_connected_component#/media/File:Scc-1.svg
    ## Modified to add a single-vertex component (by having :i -> :f edge)
    edges = [
      {:a, :b},
      {:b, :c}, {:b, :e}, {:b, :f},
      {:c, :d}, {:c, :g},
      {:d, :c}, {:d, :h},
      {:e, :a}, {:e, :f},
      {:f, :g},
      {:g, :f}, {:i, :f},
      {:h, :d}, {:h, :g}
    ]
    graph = BitGraph.new() |> BitGraph.add_edges(edges)
    strong_components = Algorithms.strong_components(graph)
    |> Enum.map(fn component -> Common.vertex_indices_to_ids(graph, component) end)
    assert length(strong_components) == 4
    assert Enum.sort(strong_components) == Enum.sort(
      [
        [:a, :b, :e],
        [:f, :g],
        [:c, :d, :h],
        [:i]
      ]
    )
  end

  test "SCC example 2" do
    edges = [
    {"A", "B"},
      {"B", "D"}, {"B", "E"},
      {"C", "F"},
      {"E", "B"}, {"E", "F"},
      {"F", "C"}, {"F", "H"},
      {"G", "H"}, {"G", "J"},
      {"H", "K"},
      {"I", "G"},
      {"J", "I"},
      {"K", "L"},
      {"L", "J"}
    ]
    graph = BitGraph.new() |> BitGraph.add_edges(edges)
    strong_components = Algorithms.strong_components(graph)
    |> MapSet.new(fn component -> Common.vertex_indices_to_ids(graph, component) end)
    assert MapSet.size(strong_components) == 5
    assert Enum.sort(strong_components) == Enum.sort(
       [
        ["A"],
        ["D"],
        ["B", "E"],
         ["C", "F"],
         ["H", "G", "J", "K", "I", "L"]
       ]
     )
  end

  test "acyclic?" do
    graph1 = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:a, :c}, {:b, :c}])
    assert Algorithms.acyclic?(graph1)

    graph2 = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:c, :a}, {:b, :c}])
    refute Algorithms.acyclic?(graph2)

    graph3 = BitGraph.new() |> BitGraph.add_edges(
      [
        {"2", "1"},
        {"2", "0"},
        {"2", "3"},
        {"3", "0"},
        {"3", "4"},
        {"1", "5"},
        {"4", "5"},
        {"0", "5"}
      ]
    )
    assert Algorithms.acyclic?(graph3)
  end

  test "get_cycle" do
    ## Acyclic graph
    graph1 = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:a, :c}, {:b, :c}])
    refute Enum.any?(BitGraph.vertex_indices(graph1),
      fn v_idx -> Algorithms.get_cycle(graph1, v_idx) end)

    ## Cyclic triangle
    graph2 = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:c, :a}, {:b, :c}])
    ## For every starting vertex, there is a cycle of length 3
    assert Enum.all?(BitGraph.vertex_indices(graph2),
      fn v_idx ->
        Algorithms.get_cycle(graph2, v_idx)
        |> MapSet.new() |> MapSet.size() == 3
      end)

    ## Bigger graph
    edges = [
      {:a, :b},
      {:b, :c}, {:b, :e}, {:b, :f},
      {:c, :d}, {:c, :g},
      {:d, :c}, {:d, :h},
      {:e, :a}, {:e, :f},
      {:f, :g},
      {:g, :f}, {:i, :f},
      {:h, :d}, {:h, :g}
    ]
    wiki_graph = BitGraph.new() |> BitGraph.add_edges(edges)
    ## No cycle for edge with a single neighbor
    refute Algorithms.get_cycle(wiki_graph, V.get_vertex_index(wiki_graph, :i))
    assert Enum.all?([:a, :b, :c, :d, :e, :f, :g],
    fn v ->
      v_idx = V.get_vertex_index(wiki_graph, v)
        Common.cycle?(
          wiki_graph,
          Algorithms.get_cycle(wiki_graph, v_idx)
      )
    end)
  end

  test "components" do
    edges = [
      {:a, :b}, {:a, :c}, {:b, :c}, # component 1
      {:d, :e}, {:d, :f}, {:e, :f}, # component 2
    ]
    graph = BitGraph.new() |> BitGraph.add_edges(edges)
    components = Algorithms.components(graph)
    assert length(components) == 2
    assert Enum.sort([MapSet.new([1, 2, 3]), MapSet.new([4, 5, 6])]) ==
      Enum.sort(components)
    single_component = BitGraph.add_edge(graph, :c, :f)
    assert length(Algorithms.components(single_component)) == 1
  end

end
