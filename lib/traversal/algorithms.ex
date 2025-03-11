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

  def components(graph) do
    Dfs.run(graph, :all, direction: :both, reduce_fun:
      fn %{root: root, acc: acc} = _state, v, _loop?  ->
        case acc do
          nil -> %{root => MapSet.new([v])}
          existing ->
            Map.update(existing, root, MapSet.new([v]),
            fn component -> MapSet.put(component, v) end)
          end
      end)
      |> Map.get(:acc)
      |> Map.values()
  end

  ## Kozaraju's
  def strong_components(graph, component_handler \\ &Function.identity/1) do
    graph
    |> Dfs.run()
    |> Dfs.order(:out, :desc)
    |> Enum.reduce({nil, []}, fn v, {state_acc, components_acc} ->
      state = Dfs.run(graph, v,
        direction: :reverse,
        state: state_acc,
        reduce_fun: fn %{acc: acc} = _state, vertex ->
          MapSet.put(acc || MapSet.new(), vertex)
        end
      )
      component = state[:acc]

      {Map.put(state, :acc, nil),
        component && [component_handler.(component) | components_acc] || components_acc}
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

end
