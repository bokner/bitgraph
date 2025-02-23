defmodule BitGraph.Algorithms do
  alias BitGraph.Dfs
  alias BitGraph.Array
  def topsort(graph) do
    Dfs.run(graph, 1)
    |> Map.get(:time_out)
    |> Array.to_list()
    |> Enum.with_index(1)
    |> Enum.sort(:desc)
    |> Enum.map(fn {_time_out, vertex_idx} -> vertex_idx end)
  end
end
