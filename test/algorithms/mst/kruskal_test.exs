defmodule BitGraphTest.Algorithm.MST.Kruskal do
  alias BitGraph.Algorithm.MST.Kruskal
  use ExUnit.Case, async: false

  describe "MST (Kruskal)" do
    test "Wikipedia example (https://en.wikipedia.org/wiki/File:Kruskal_Algorithm_6.svg)" do
      # {from, to, weight}
      edge_data = [
        {:A, :B, 7},
        {:A, :D, 5},
        {:B, :C, 8},
        {:B, :D, 9},
        {:B, :E, 7},
        {:C, :E, 5},
        {:D, :E, 15},
        {:D, :F, 6},
        {:E, :F, 8},
        {:E, :G, 9},
        {:F, :G, 11}
      ]

      {distances, graph} =
        initialize_graph(edge_data)

      {edges, weight} = Kruskal.run(graph,
        dist_fun: fn from, to -> Map.get(distances, {from, to}) end
      )

      ## Edges form the tree
      assert length(edges) == BitGraph.num_vertices(graph) - 1

      assert 39 = weight
      assert MapSet.new(edges) == MapSet.new(
        [A: :B, A: :D, B: :E, C: :E, D: :F,  E: :G]
      )
    end

    test "Example 2" do
      edge_data = [
        {:A, :B, 5},
        {:A, :D, 4},
        {:A, :E, 1},
        {:B, :C, 4},
        {:B, :D, 2},
        {:C, :H, 4},
        {:C, :I, 1},
        {:C, :J, 2},
        {:D, :E, 2},
        {:D, :F, 5},
        {:D, :G, 11},
        {:D, :H, 2},
        {:E, :F, 1},
        {:F, :G, 7},
        {:G, :H, 1},
        {:G, :I, 4},
        {:H, :I, 6},
        {:I, :J, 0}
      ]
      {distances, graph} =
        initialize_graph(edge_data)

      {edges, weight} = Kruskal.run(graph,
        dist_fun: fn from, to -> Map.get(distances, {from, to}) end
      )

      ## Edges form the tree
      assert length(edges) == BitGraph.num_vertices(graph) - 1

      assert 14 = weight
      assert MapSet.new(edges) == MapSet.new(
        [A: :E, B: :C, B: :D, C: :I, D: :E, D: :H, E: :F, G: :H, I: :J]
      )

    end

    defp initialize_graph(edge_data) do
        Enum.reduce(edge_data, {Map.new(), BitGraph.new()}, fn {from, to, d}, {dist_acc, g_acc} ->
          {Map.put(dist_acc, {from, to}, d), BitGraph.add_edge(g_acc, from, to)}
        end)
    end
  end

end
