defmodule BitGraphTest.Common do
  use ExUnit.Case
  alias BitGraph.Common

  test "check if a sequence of vertices is a valid cycle" do
    acyclic_graph = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:a, :c}, {:b, :c}])
    refute Common.cycle?(acyclic_graph, BitGraph.vertex_indices(acyclic_graph))

    cycle = BitGraph.new() |> BitGraph.add_edges([{:a, :b}, {:c, :a}, {:b, :c}])
    assert Common.cycle?(cycle, BitGraph.vertex_indices(cycle))
  end
end
