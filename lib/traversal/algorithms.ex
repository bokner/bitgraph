defmodule BitGraph.Algorithms do
  alias BitGraph.Dfs
  alias BitGraph.Array
  alias BitGraph.{E}

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
      Dfs.run(graph, vertex, reduce_fun:
        fn %{acc: acc} = state, v, loop?  ->
          if loop? && (v == vertex) do
              {:stop,
                build_cycle(graph, vertex, state[:parent])
              }
            else
              {:next, acc}
            end
        end
      )
      |> Map.get(:acc)
    else
      false
    end
  end

    ## Build cycle starting from vertex
    defp build_cycle(graph, start_vertex, parents_ref) do
      build_cycle(graph, start_vertex, parents_ref, [start_vertex])
    end

    ## Move from vertices to their parents starting from given vertex
    defp build_cycle(graph, start_vertex, parents_ref, acc) do
      build_cycle(graph, start_vertex, Array.get(parents_ref, start_vertex), parents_ref, acc)
    end

    defp build_cycle(graph, start_vertex, vertex, parents_ref, acc) do
      # Stop if we find vertex that is an out-neighbor of the vertex
      # we started with.
      if E.edge?(graph, start_vertex, vertex) do
        [vertex | acc]
      else
        next_vertex = Array.get(parents_ref, vertex)
        build_cycle(graph, start_vertex, next_vertex, parents_ref, [vertex | acc])
      end
    end


  # defp build_cycle(start, sequence) do
  #   build_cycle(Array.get(sequence, start), sequence, [start], MapSet.new([start]))
  # end

  # defp build_cycle(next, sequence, acc, visited) do
  #   if next == 0 || (next in visited) do
  #     acc
  #   else
  #     build_cycle(
  #       Array.get(sequence, next),
  #       sequence,
  #       [next | acc],
  #       MapSet.put(visited, next))
  #   end
  # end
end
