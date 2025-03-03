defmodule BitGraph.Algorithms do
  alias BitGraph.Dfs
  alias BitGraph.Array
  alias BitGraph.{E, V}

  def topsort(graph) do
    graph
    |> Dfs.run()
    |> then(fn state ->
      Dfs.acyclic?(state) && Dfs.order(state, :out, :desc) || false
    end)
  end

  def acyclic?(graph) do
    graph
    |> BitGraph.vertex_indices()
    |> Enum.reduce_while(nil, fn v, state_acc ->
      state_acc = Dfs.run(graph, v, state: state_acc)
      Dfs.acyclic?(state_acc) && {:halt, true} || {:cont, state_acc}
    end)
    |> then(
      fn true -> true
      _ -> false
    end)
  end

  def strong_components(graph) do
    graph
    |> Dfs.run()
    |> Dfs.order(:out, :desc)
    |> Enum.reduce({nil, []}, fn v, {state_acc, components_acc} ->
      state = Dfs.run(graph, v,
        reverse_dfs: true,
        state: state_acc,
        reduce_fun: fn %{acc: acc} = _state, vertex ->
          MapSet.put(acc || MapSet.new(), vertex)
        end
      )
      component = state[:acc]

      {Map.put(state, :acc, nil),
        component && [component | components_acc] || components_acc}
    end)
    |> elem(1)
  end

  def get_cycle(graph, vertex) when is_integer(vertex) do
    if E.in_degree(graph, vertex) > 0 && E.out_degree(graph, vertex) > 0 do
      state = Dfs.run(graph, vertex, reduce_fun:
        fn %{acc: acc} = state, v, loop?  ->
          IO.inspect({V.get_vertex(graph, v), loop?}, label: :vertex)
          if loop? && E.edge?(graph, v, vertex) do
            IO.inspect("Back edge!")
            {:stop, build_cycle(vertex, state[:parent])
          }
          else
            {:next, false}
          end

          #vertex_color(graph, v) == @gray_vertex
        end
      )
      #!Dfs.acyclic?(state) && build_cycle(vertex, state[:parent])
      state[:acc]
    else
      false
    end
  end

  defp build_cycle(start, sequence) do
    build_cycle(Array.get(sequence, start), sequence, [start], MapSet.new([start]))
  end

  defp build_cycle(next, sequence, acc, visited) do
    if next == 0 || (next in visited) do
      acc
    else
      build_cycle(
        Array.get(sequence, next),
        sequence,
        [next | acc],
        MapSet.put(visited, next))
    end
  end
end
