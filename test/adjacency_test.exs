defmodule BitGraphTest.Adjacency do
  use ExUnit.Case
  alias BitGraph.Adjacency

  test "create adjacency table" do
    assert Enum.all?(
             Enum.take_random(1..1000, 100),
             fn v_num ->
               %{table_dimension: dimension, bit_vector: {:bit_vector, ref}} =
                 Adjacency.init_adjacency_table(v_num)

               dimension == v_num &&
                 div((:atomics.info(ref)[:size] - 2) * 64 - v_num * v_num, 64) <= 1
             end
           )
  end

  test "get/set/clear entries in adjacency table" do
    num_vertices = Enum.random(1..1000)
    adjacency_table = Adjacency.init_adjacency_table(num_vertices)

    assert Enum.all?(1..num_vertices, fn i ->
             Enum.all?(1..num_vertices, fn j ->
               Adjacency.get(adjacency_table, i, j) == 0
             end)
           end)

    Enum.each(1..num_vertices, fn i ->
      Enum.each(1..num_vertices, fn j ->
        Adjacency.set(adjacency_table, i, j)
      end)
    end)

    assert Enum.all?(1..num_vertices, fn i ->
             Enum.all?(1..num_vertices, fn j ->
               Adjacency.get(adjacency_table, i, j) == 1
             end)
           end)

    Enum.each(1..num_vertices, fn i ->
      Enum.each(1..num_vertices, fn j ->
        Adjacency.clear(adjacency_table, i, j)
      end)
    end)

    assert Enum.all?(1..num_vertices, fn i ->
             Enum.all?(1..num_vertices, fn j ->
               Adjacency.get(adjacency_table, i, j) == 0
             end)
           end)
  end

  test "get row from adjacency table" do
    num_vertices = 10
    adjacency_table = Adjacency.init_adjacency_table(num_vertices)

    Adjacency.set(adjacency_table, 1, 2)
    Adjacency.set(adjacency_table, 1, 3)
    Adjacency.set(adjacency_table, 4, 1)
    Adjacency.set(adjacency_table, 3, 2)

    assert Adjacency.row(adjacency_table, 1) == MapSet.new([2, 3])
    assert Adjacency.row(adjacency_table, 2) == MapSet.new()
    assert Adjacency.row(adjacency_table, 3) == MapSet.new([2])

    assert Adjacency.column(adjacency_table, 1) == MapSet.new([4])
    assert Adjacency.column(adjacency_table, 2) == MapSet.new([1, 3])
    assert Adjacency.column(adjacency_table, 3) == MapSet.new([1])
    assert Adjacency.column(adjacency_table, 4) == MapSet.new()

    assert Enum.all?(5..10, fn i ->
             Adjacency.row(adjacency_table, i) == MapSet.new() &&
               Adjacency.column(adjacency_table, i) == MapSet.new()
           end)
  end

  test "copy adjacency table" do
    num_vertices = Enum.random(2..1000)
    adjacency_table = Adjacency.init_adjacency_table(num_vertices)
    for i <- 1..num_vertices, j <- 1..num_vertices, i != j do
      :rand.uniform() <= 0.5 && Adjacency.set(adjacency_table, i, j)
    end

    copy = Adjacency.copy(adjacency_table)

    assert Enum.all?(1..num_vertices, fn i ->
             Enum.all?(1..num_vertices, fn j ->
               Adjacency.get(adjacency_table, i, j) ==
                Adjacency.get(copy, i, j)
             end)
           end)

  end
end
