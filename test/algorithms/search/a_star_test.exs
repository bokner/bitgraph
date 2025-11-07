defmodule BitGraphTest.Algorithm.Search.AStar do
  alias BitGraph.Algorithm.Search.AStar
  use ExUnit.Case, async: false

  describe "A* search, algorithm" do
    test "Dijkstra example (https://en.wikipedia.org/wiki/File:Dijkstra_Animation.gif)" do
      # {from, to, weight}
      edge_data = [
        {1, 2, 7},
        {1, 3, 9},
        {1, 6, 14},
        {2, 3, 10},
        {2, 4, 15},
        {3, 4, 11},
        {3, 6, 2},
        {4, 5, 6},
        {6, 5, 9}
      ]

      {distances, graph} =
        BitGraph.new()
        |> BitGraph.add_vertices([1, 2, 3, 4, 5, 6])
        |> then(fn g ->
          Enum.reduce(edge_data, {Map.new(), g}, fn {from, to, d}, {dist_acc, g_acc} ->
            {Map.put(dist_acc, {from, to}, d), BitGraph.add_edge(g_acc, from, to)}
          end)
        end)

      assert [1, 3, 6, 5] ==
               AStar.run(graph, 1, 5, fn _vertex -> 0 end, fn from, to ->
                 Map.get(distances, {from, to})
               end)
    end
  end

  describe "A* search, API" do
    test "https://en.wikipedia.org/wiki/A*_search_algorithm#/media/File:AstarExampleEn.gif" do
      edge_data = [
        {:green, :a, 1.5},
        {:green, :d, 2},
        {:a, :b, 2},
        {:b, :c, 3},
        {:c, :blue, 4},
        {:d, :e, 3},
        {:e, :blue, 2}
      ]

      h_values =
        Map.new([
          {:a, 4},
          {:b, 2},
          {:c, 4},
          {:d, 4.5},
          {:e, 2}
        ])

      h_fun = fn v -> Map.get(h_values, v) end

      {distances, graph} =
        Enum.reduce(edge_data, {Map.new(), BitGraph.new()}, fn {from, to, d}, {dist_acc, g_acc} ->
          {Map.put(dist_acc, {from, to}, d), BitGraph.add_edge(g_acc, from, to)}
        end)

      assert [:green, :d, :e, :blue] =
               BitGraph.a_star(graph, :green, :blue,
                 dist_fun: fn from, to -> Map.get(distances, {from, to}) end,
                 h_fun: h_fun
               )
    end

    test "https://www.codecademy.com/resources/docs/ai/search-algorithms/a-star-search" do
      h_values = %{B: 6, S: 7, E: 3, G: 0, H: 7, A: 8, C: 5, D: 5, F: 3, I: 4, J: 5, K: 3}

      edge_data = [
        {:K, :G, 16},
        {:J, :K, 7},
        {:I, :J, 5},
        {:I, :G, 5},
        {:I, :K, 13},
        {:F, :G, 13},
        {:D, :H, 16},
        {:D, :I, 20},
        {:D, :F, 1},
        {:C, :F, 2},
        {:C, :E, 20},
        {:C, :D, 8},
        {:A, :D, 5},
        {:A, :B, 8},
        {:H, :I, 1},
        {:H, :J, 2},
        {:E, :G, 19},
        {:S, :C, 11},
        {:S, :B, 10},
        {:S, :A, 4},
        {:B, :D, 15}
      ]

      h_fun = fn v -> Map.get(h_values, v) end

      {distances, graph} =
        Enum.reduce(edge_data, {Map.new(), BitGraph.new()}, fn {from, to, d}, {dist_acc, g_acc} ->
          {Map.put(dist_acc, {from, to}, d), BitGraph.add_edge(g_acc, from, to)}
        end)

      assert [:S, :A, :D, :F, :G] = BitGraph.a_star(graph, :S, :G,
        dist_fun: fn from, to -> Map.get(distances, {from, to}) end,
        h_fun: h_fun
      )
    end
  end
end
