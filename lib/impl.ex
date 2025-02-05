defmodule BitGraph.Impl do
  def init_adjacency_table() do
    Arrays.new([segment(1)])
  end

  defp segment(n) do
    :atomics.new(1, signed: false)
  end
end
