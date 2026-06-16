defmodule BitGraphTest.Algorithm.MST.Kruskal do
  alias BitGraph.MST.Kruskal
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
        Enum.reduce(edge_data, {Map.new(), BitGraph.new()}, fn {from, to, d}, {dist_acc, g_acc} ->
          {Map.put(dist_acc, {from, to}, d), BitGraph.add_edge(g_acc, from, to)}
        end)

      {edges, weight} = Kruskal.run(graph,
        dist_fun: fn from, to -> Map.get(distances, {from, to}) end
      )

      assert 39 = weight
      assert MapSet.new(edges) == MapSet.new(
        [A: :B, A: :D, B: :E, D: :F, C: :E, E: :G]
      )
    end
  end

  # describe "A* search, API" do
  #   test "https://en.wikipedia.org/wiki/A*_search_algorithm#/media/File:AstarExampleEn.gif" do
  #     edge_data = [
  #       {:green, :a, 1.5},
  #       {:green, :d, 2},
  #       {:a, :b, 2},
  #       {:b, :c, 3},
  #       {:c, :blue, 4},
  #       {:d, :e, 3},
  #       {:e, :blue, 2}
  #     ]

  #     h_values =
  #       Map.new([
  #         {:a, 4},
  #         {:b, 2},
  #         {:c, 4},
  #         {:d, 4.5},
  #         {:e, 2}
  #       ])

  #     h_fun = fn v -> Map.get(h_values, v) end

  #     {distances, graph} =
  #       Enum.reduce(edge_data, {Map.new(), BitGraph.new()}, fn {from, to, d}, {dist_acc, g_acc} ->
  #         {Map.put(dist_acc, {from, to}, d), BitGraph.add_edge(g_acc, from, to)}
  #       end)

  #     assert [:green, :d, :e, :blue] =
  #              BitGraph.a_star(graph, :green, :blue,
  #                dist_fun: fn from, to -> Map.get(distances, {from, to}) end,
  #                h_fun: h_fun
  #              )
  #   end

  #   test "https://www.codecademy.com/resources/docs/ai/search-algorithms/a-star-search" do
  #     h_values = %{B: 6, S: 7, E: 3, G: 0, H: 7, A: 8, C: 5, D: 5, F: 3, I: 4, J: 5, K: 3}

  #     edge_data = [
  #       {:K, :G, 16},
  #       {:J, :K, 7},
  #       {:I, :J, 5},
  #       {:I, :G, 5},
  #       {:I, :K, 13},
  #       {:F, :G, 13},
  #       {:D, :H, 16},
  #       {:D, :I, 20},
  #       {:D, :F, 1},
  #       {:C, :F, 2},
  #       {:C, :E, 20},
  #       {:C, :D, 8},
  #       {:A, :D, 5},
  #       {:A, :B, 8},
  #       {:H, :I, 1},
  #       {:H, :J, 2},
  #       {:E, :G, 19},
  #       {:S, :C, 11},
  #       {:S, :B, 10},
  #       {:S, :A, 4},
  #       {:B, :D, 15}
  #     ]

  #     h_fun = fn v -> Map.get(h_values, v) end

  #     {distances, graph} =
  #       Enum.reduce(edge_data, {Map.new(), BitGraph.new()}, fn {from, to, d}, {dist_acc, g_acc} ->
  #         {Map.put(dist_acc, {from, to}, d), BitGraph.add_edge(g_acc, from, to)}
  #       end)

  #     assert [:S, :A, :D, :F, :G] = BitGraph.a_star(graph, :S, :G,
  #       dist_fun: fn from, to -> Map.get(distances, {from, to}) end,
  #       h_fun: h_fun
  #     )
  #   end
  # end
end
