defmodule BitGraphTest.Algorithms do
  use ExUnit.Case

  alias BitGraph.Algorithms

  test "topsort" do
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
      BitGraph.new()
      |> BitGraph.add_edges(
        edges
      )

    topsort_result = Algorithms.topsort(graph)
    Enum.all?(edges,
        fn {from, to} ->
          Enum.find_index(topsort_result, fn val -> val == from end)
          < Enum.find_index(topsort_result, fn val -> val == to end)
        end)
  end
end
