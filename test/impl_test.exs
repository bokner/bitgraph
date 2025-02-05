defmodule BitGraphTest.Adjacency do
  use ExUnit.Case
  alias BitGraph.Adjacency

  test "adjacency table allocation" do
    assert Enum.all?(
      [{8, 1}, {32, 16}, {1000, 16384}, {10000, 2048*2048}], fn {v, expected_atomics_size} ->
        allocated = Adjacency.allocate(v)
        atomics_size = Adjacency.table_ref(allocated) |> :atomics.info() |> get_in([:size])
        table_dimension = :math.sqrt(atomics_size)
        atomics_size == expected_atomics_size
        ## Adjacency table is a square matrix
        && floor(table_dimension) == table_dimension
      end)
  end
end
