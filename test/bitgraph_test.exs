defmodule BitGraphTest do
  use ExUnit.Case

  alias BitGraph.{V, Adjacency}

  describe "BitGraph" do
    test "create graph" do
      graph = BitGraph.new()
      assert graph.vertices.num_vertices == 0
    end

    test "copy graph" do
      edge_data = %{label: "a->b"}
      graph =
        BitGraph.new()
        |> BitGraph.add_vertex(:a, %{label: "a"})
        |> BitGraph.add_vertex(:b, %{label: "b"})
        |> BitGraph.add_edge(:a, :b, edge_data)
      copy = BitGraph.copy(graph)

      assert MapSet.size(BitGraph.vertices(graph)) == 2
      assert MapSet.size(BitGraph.out_edges(copy, :a)) == 1
      assert MapSet.size(BitGraph.in_edges(copy, :b)) == 1

      assert BitGraph.get_vertex(copy, :a, [:opts, :label]) == "a"
      assert BitGraph.get_vertex(copy, :b, [:opts, :label]) == "b"
      assert BitGraph.get_edge(copy, :a, :b) |> Map.get(:opts) == edge_data
    end

    test "add vertex" do
      graph = BitGraph.new()
      graph = BitGraph.add_vertex(graph, "A")
      assert graph.vertices.num_vertices == 1
      ## Adding existing vertex should not increase the number of vertices
      graph = BitGraph.add_vertex(graph, "A")
      assert  BitGraph.num_vertices(graph) == 1
      ## Adding a new vertex should increase the number of vertices
      graph = BitGraph.add_vertex(graph, "B")
      assert BitGraph.num_vertices(graph) == 2
    end

    test "get/update vertex info" do
      graph = BitGraph.new()
      vertex_data = [label: "a", weight: 1]
      graph = BitGraph.add_vertex(graph, :a, vertex_data)
      assert BitGraph.get_vertex(graph, :a, [:opts]) == vertex_data
       and BitGraph.get_vertex(graph, :a, [:opts, :weight]) == 1
       and BitGraph.get_vertex(graph, :a, [:vertex]) == :a
      refute BitGraph.get_vertex(graph, :a, [:something])

      updated_data = [label: "a2", weight: 2]
      graph = BitGraph.update_vertex(graph, :a, updated_data)
      assert BitGraph.get_vertex(graph, :a, [:opts]) == updated_data

      ## Vertex not in graph
      refute BitGraph.get_vertex(graph, :c)
      refute BitGraph.update_vertex(graph, :c, vertex_data)
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
      assert 2 == BitGraph.num_edges(graph)
      graph = BitGraph.add_edge(graph, %BitGraph.E{from: "C", to: "A"})
      assert 3 == BitGraph.edges(graph, "A") |> MapSet.size()
      assert 1 == BitGraph.edges(graph, "C") |> MapSet.size()
    end

    test "delete edge" do
      graph = BitGraph.new() |> BitGraph.add_edge(:v1, :v2)
      assert map_size(graph.edges) == 1
      assert adjacent_vertices?(graph, :v1, :v2)
      ## Try to delete non-existing edge
      graph = BitGraph.delete_edge(graph, :v1, :v3)
      assert map_size(graph.edges) == 1
      ## Delete existing edge
      graph = BitGraph.delete_edge(graph, :v1, :v2)
      assert BitGraph.num_edges(graph) == 0
      refute adjacent_vertices?(graph, :v1, :v2)
      ## Delete BitGraph.E
      graph = BitGraph.add_edge(graph, :v3, :v4)
      edge = BitGraph.get_edge(graph, :v3, :v4)
      assert graph |> BitGraph.delete_edge(edge) |> BitGraph.num_edges() == 0
    end

    test "delete vertex" do
      graph = BitGraph.new()
      graph = BitGraph.add_edge(graph, :a, :b)
      assert BitGraph.num_vertices(graph) == 2
      assert BitGraph.vertex_indices(graph) |> Enum.sort() == [1, 2]
      assert map_size(graph.edges) == 1

      assert adjacent_vertices?(graph, :a, :b)

      graph = BitGraph.delete_vertex(graph, :a)
      assert BitGraph.num_vertices(graph) == 1
      assert BitGraph.vertex_indices(graph) == [2]
      assert map_size(graph.edges) == 0
      refute adjacent_vertices?(graph, :a, :b)

    end

    test "neighbors" do
      graph = BitGraph.new()
      graph = BitGraph.add_edge(graph, :a, :b)
      assert BitGraph.in_neighbors(graph, :a) == MapSet.new([])
      assert BitGraph.out_neighbors(graph, :a) == MapSet.new([:b])
      assert BitGraph.in_neighbors(graph, :b) == MapSet.new([:a])
      assert BitGraph.out_neighbors(graph, :b) == MapSet.new([])
      ## Vertex not in graph
      assert BitGraph.in_neighbors(graph, :c) == MapSet.new([])
      assert BitGraph.out_neighbors(graph, :c) == MapSet.new([])
      ## Add BitGraph.E
      graph = BitGraph.add_edge(graph, %BitGraph.E{from: :c, to: :a})
      assert  BitGraph.in_neighbors(graph, :a) == MapSet.new([:c])
      assert  BitGraph.out_neighbors(graph, :c) == MapSet.new([:a])

    end

    test "degrees" do
      graph = BitGraph.new()
      graph = BitGraph.add_edge(graph, :a, :b)
      assert BitGraph.in_degree(graph, :a) == 0
      assert BitGraph.out_degree(graph, :a) == 1
      assert BitGraph.in_degree(graph, :b) == 1
      assert BitGraph.out_degree(graph, :b) == 0
      ## Vertex not in graph
      assert BitGraph.in_degree(graph, :c) == 0
      assert BitGraph.out_degree(graph, :c) == 0
      refute BitGraph.isolated_vertex?(graph, :c)
      ## Isolated vertex
      graph = BitGraph.delete_edge(graph, :a, :b)
      assert BitGraph.isolated_vertex?(graph, :a) && BitGraph.isolated_vertex?(graph, :b)

    end

    defp adjacent_vertices?(graph, v1, v2) do
      graph[:adjacency]
      |> Adjacency.get(V.get_vertex_index(graph, v1),
      V.get_vertex_index(graph, v2)
      ) == 1
    end

  end

  test "subgraph" do
    graph = BitGraph.new() |> BitGraph.add_vertices([:a, :b, :c, :d]) |> BitGraph.add_edges(
      [
        {:a, :b}, {:a, :c}, {:a, :d},
        {:b, :c}, {:b, :d},
        {:c, :d}
      ])

     subgraph = BitGraph.subgraph(graph, [:a, :b, :c])
     assert_subgraph(subgraph)
     ## The parent graph is not affected
     assert BitGraph.num_vertices(graph) == 4
     assert BitGraph.num_edges(graph) == 6
     ## Removing vertex from parent graph does not affect a detached subgraph
     graph2 = BitGraph.delete_vertex(graph, :a)
     assert BitGraph.num_vertices(graph2) == 3
     assert_subgraph(subgraph)
     ## Removing vertex from subgraph does not affect the parent graph
     _subgraph2 = BitGraph.delete_vertex(subgraph, :a)
     assert BitGraph.num_vertices(graph) == 4

  end


  defp assert_subgraph(subgraph) do
    assert Enum.sort(BitGraph.vertices(subgraph)) == Enum.sort([:a, :b, :c])
    assert BitGraph.num_edges(subgraph) == 3
    assert BitGraph.out_neighbors(subgraph, :a) == MapSet.new([:c, :b])
    assert BitGraph.out_neighbors(subgraph, :b) == MapSet.new([:c])
    assert BitGraph.in_neighbors(subgraph, :b) == MapSet.new([:a])
    assert BitGraph.in_neighbors(subgraph, :c) == MapSet.new([:a, :b])
  end
end
