defmodule BitGraph.Algorithms do
  alias BitGraph.Dfs
  alias BitGraph.Array

  def topsort(graph) do
    Dfs.run(graph)
    |> Map.get(:time_out)
    |> Array.to_list()
    |> Enum.with_index(1)
    |> Enum.sort(:desc)
    |> Enum.map(fn {_time_out, vertex_idx} -> vertex_idx end)
  end

  def strong_components(graph) do
    graph
    |> topsort()
    |> Enum.reduce({nil, []}, fn v, {state_acc, components_acc} ->
      state = Dfs.run(graph, v,
        reverse_dfs: true,
        state: state_acc,
        reduce_fun: fn _graph, vertex, %{acc: acc} = _state ->
          MapSet.put(acc || MapSet.new(), vertex)
        end
      )
      component = state[:acc]

      {Map.put(state, :acc, nil),
        component && [component | components_acc] || components_acc}
    end)
    |> elem(1)
  end
end
