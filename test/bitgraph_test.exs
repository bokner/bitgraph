defmodule BitGraphTest do
  use ExUnit.Case

  alias BitGraph.Adjacency

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

    test "delete edge" do
      graph = BitGraph.new()
      graph = BitGraph.add_edge(graph, :v1, :v2)
      assert map_size(graph.edges) == 1
      assert adjacent_vertices?(graph, :v1, :v2)
      ## Try to delete non-existing edge
      graph = BitGraph.delete_edge(graph, :v1, :v3)
      assert map_size(graph.edges) == 1
      ## Delete existing edge
      graph = BitGraph.delete_edge(graph, :v1, :v2)
      assert map_size(graph.edges) == 0
      refute adjacent_vertices?(graph, :v1, :v2)
    end

    test "delete vertex" do
      graph = BitGraph.new()
      graph = BitGraph.add_edge(graph, :a, :b)
      assert graph.vertices.num_vertices == 2
      assert map_size(graph.edges) == 1

      assert adjacent_vertices?(graph, :a, :b)

      graph = BitGraph.delete_vertex(graph, :b)
      assert graph.vertices.num_vertices == 1
      assert map_size(graph.edges) == 0
      refute adjacent_vertices?(graph, :a, :b)

    end

    defp adjacent_vertices?(graph, v1, v2) do
      graph[:adjacency]
      |> Adjacency.get(BitGraph.get_vertex_index(graph, v1),
      BitGraph.get_vertex_index(graph, v2)
      ) == 1
    end

  end
end
