defmodule BitGraphTest.Algorithm.SCC do
  use ExUnit.Case

  alias BitGraph.Algorithm.SCC
  alias BitGraph.Common

  test "Strongly connected graph" do
    graph = strongly_connected_graph_example()
    assert SCC.Tarjan.strongly_connected?(graph)
    assert SCC.Kozaraju.strongly_connected?(graph)
  end

  test "DAG is not strongly connected" do
    graph = tree_example()
    refute SCC.Tarjan.strongly_connected?(graph)
    refute SCC.Kozaraju.strongly_connected?(graph)
  end

  test "Single SCC" do
    graph = strongly_connected_graph_example()
    assert hd(SCC.Kozaraju.run(graph)) == MapSet.new(1..7)
    assert hd(SCC.Tarjan.run(graph)) == MapSet.new(1..7)
  end

  test "SCC examples with multiple components" do
    Enum.each(
      [graph_example_1(), graph_example_2(), graph_example_3()],
      fn {graph, valid_sccs} ->
        Enum.each([
          ## Test direct call
          SCC.Kozaraju.run(graph),
          SCC.Tarjan.run(graph)
          ],
        fn strong_components ->
        normalized_sccs = Enum.map(strong_components, fn component -> Common.vertex_indices_to_ids(graph, component) end)
        assert Enum.sort(normalized_sccs) == Enum.sort(valid_sccs)
        end)
      end)

  end

  test "SCC for empty graph" do
    graph = BitGraph.new()
    assert SCC.Kozaraju.run(graph) == []
    assert SCC.Tarjan.run(graph) == []
  end


  defp strongly_connected_graph_example() do
    vertices = 1..7
    edges =
    [
      {1, 2}, {1, 5}, {1, 6},
      {2, 3}, {2, 4},
      {3, 1},
      {4, 3},
      {5, 2}, {5, 4},
      {6, 1}, {6, 7},
      {7, 4}, {7, 5}
    ]
    BitGraph.new() |> BitGraph.add_vertices(vertices) |> BitGraph.add_edges(edges)
  end

  defp tree_example() do
    edges = [
      {1, 2}, {1, 3}, {1, 4},
      {2, 5}, {2, 6}, {2, 7},
      {3, 8}, {3, 9},
      {4, 10}, {4, 11},
      {5, 12}
    ]
    BitGraph.new() |> BitGraph.add_edges(edges)
  end

  defp graph_example_1() do
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
    valid_sccs = [
      [:a, :b, :e],
      [:f, :g],
      [:c, :d, :h],
      [:i]
    ]

    {BitGraph.new() |> BitGraph.add_edges(edges), valid_sccs}
  end

  defp graph_example_2() do
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

    valid_sccs = [
      ["A"],
      ["D"],
      ["B", "E"],
       ["C", "F"],
       ["H", "G", "J", "K", "I", "L"]
     ]

    {BitGraph.new() |> BitGraph.add_edges(edges), valid_sccs}
  end

  defp graph_example_3() do
    # https://www.baeldung.com/cs/scc-tarjans-algorithm#the-pseudocode-of-the-algorithm
    edges = [
      {:a, :b},
      {:b, :c}, {:b, :d},
      {:c, :a},
      {:d, :e},
      {:e, :f},
      {:f, :e},
      {:g, :e}, {:g, :h},
      {:h, :f}, {:h, :i},
      {:i, :j},
      {:j, :g}, {:j, :h}
    ]

    valid_sccs = [
      [:e, :f],
      [:d],
      [:a, :b, :c],
      [:g, :h, :i, :j]
    ]

    {BitGraph.new() |> BitGraph.add_edges(edges), valid_sccs}

  end

end
