defmodule BitGraphTest.Algorithms.SCC do
  use ExUnit.Case

  alias BitGraph.Algorithms.SCC
  alias BitGraph.Algorithms

  alias BitGraph.Common


  test "Single SCC" do
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
    graph = BitGraph.new() |> BitGraph.add_vertices(vertices) |> BitGraph.add_edges(edges)
    #assert hd(SCC.kozaraju(graph)) == MapSet.new(1..7)
    assert hd(SCC.tarjan(graph)) == MapSet.new(1..7)
  end

  test "SCC examples with multiple components" do
    Enum.each(
      [graph_example_1(), graph_example_2(), graph_example_3()],
      fn {graph, valid_sccs} ->
        Enum.each([
          ## Test direct call
          SCC.kozaraju(graph),
          SCC.tarjan(graph),
          ## Test API
          Algorithms.strong_components(graph, algorithm: :kozaraju),
          Algorithms.strong_components(graph, algorithm: :tarjan)
          ],
        fn strong_components ->
        normalized_sccs = Enum.map(strong_components, fn component -> Common.vertex_indices_to_ids(graph, component) end)
        assert Enum.sort(normalized_sccs) == Enum.sort(valid_sccs)
        end)
      end)
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
