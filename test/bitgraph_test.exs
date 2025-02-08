defmodule BitGraphTest do
  use ExUnit.Case

  describe "BitGraph" do
    test "create graph" do
      graph = BitGraph.new()
      assert graph.vertices.num_vertices == 0
    end

    test "add vertex" do
      graph = BitGraph.new()
      graph = BitGraph.add_vertex(graph, "A")
      assert graph.vertices.num_vertices == 1
      ## Adding existing vertex should not increase the number of vertices
      graph = BitGraph.add_vertex(graph, "A")
      assert graph.vertices.num_vertices == 1
      ## Adding a new vertex should increase the number of vertices
      graph = BitGraph.add_vertex(graph, "B")
      assert graph.vertices.num_vertices == 2
    end

    test "add edge" do
      graph = BitGraph.new()
      graph = BitGraph.add_edge(graph, "A", "B")
      assert BitGraph.in_edges(graph, "A") == MapSet.new([])
      [a_b_edge] = BitGraph.in_edges(graph, "B") |> MapSet.to_list()
      assert a_b_edge.from == "A"
      assert a_b_edge.to == "B"
      graph = BitGraph.add_edge(graph, "B", "A")
      [b_a_edge] = BitGraph.out_edges(graph, "B") |> MapSet.to_list()
      assert b_a_edge.from == "B"
      assert b_a_edge.to == "A"
      assert 2 == BitGraph.edges(graph, "A") |> MapSet.size()
      assert 2 == BitGraph.edges(graph, "B") |> MapSet.size()
    end

  end
end
