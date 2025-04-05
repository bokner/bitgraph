defmodule BitGraphTest.Dfs do
  use ExUnit.Case

  alias BitGraph.Dfs

  test "edge classification" do
    tree_edges = [{1, 2}, {2, 4}, {4, 6}, {1, 3}, {3, 5}, {5, 7}, {5, 8}]
    forward_edges = [{1, 8}]
    back_edges =  [{6, 2}]
    cross_edges = [{5, 4}]

    all_edges = tree_edges ++ forward_edges ++ back_edges ++ cross_edges
    graph = BitGraph.new() |> BitGraph.add_vertices(1..8) |> BitGraph.add_edges(all_edges)

    type_map =
    Dfs.run(graph, :all, process_edge_fun:
      fn %{acc: acc} = _state, from, to, edge_type ->
        [{edge_type, {from, to}} | acc || []]
      end
    )
    |> Map.get(:acc)
    |> Enum.group_by(fn {type, _edge} -> type end, fn {_type, edge} -> edge end)

    assert_equal_edges(type_map, :tree, tree_edges)
    assert_equal_edges(type_map, :back, back_edges)
    assert_equal_edges(type_map, :forward, forward_edges)
    assert_equal_edges(type_map, :cross, cross_edges)

  end

  defp assert_equal_edges(type_map, type, edges) do
    assert Map.get(type_map, type) |> Enum.sort() == Enum.sort(edges)
  end
end
