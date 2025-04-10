defmodule BitGraph.Algorithms.SCC do
  alias BitGraph.{Dfs, Array, Stack}

  ## Kozaraju's SCC algorithm
  def kozaraju(graph,
    component_handler \\ fn component, _state -> component end,
    precheck \\ fn state -> state end,
    first_run_opts \\ []
    ) do
    graph
    |> Dfs.run(first_run_opts)
    |> then(fn state -> precheck.(state) end)
    |> Dfs.order(:out, :desc)
    |> Enum.reduce({nil, []}, fn v, {state_acc, components_acc} ->
      state =
        Dfs.run(graph, v,
          direction: :reverse,
          state: state_acc,
          process_vertex_fun: fn %{acc: acc} = _state, vertex ->
            MapSet.put(acc || MapSet.new(), vertex)
          end
        )

      component = state[:acc]

      {Map.put(state, :acc, nil),
       (component && [component_handler.(component, state) | components_acc]) || components_acc}
    end)
    |> elem(1)
  end

  @doc """
    Tarjan algo for SCC.
    Roughly follows https://blog.heycoach.in/tarjans-algorithm-in-graph-theory/
  """

  def tarjan(graph, component_handler \\ fn component, _state -> component end,
    no_loop_handler \\ fn state -> state[:acc] end
  ) do
    graph
    |> Dfs.run(
      process_vertex_fun: fn state, v, event ->
        tarjan_vertex(state, v, event,
          component_handler: component_handler,
          no_loop_handler: no_loop_handler,
          num_vertices: BitGraph.num_vertices(graph)
        )
      end,
      process_edge_fun: &tarjan_edge/4,
      edge_process_order: :postorder
    )
    |> get_in([:acc, :sccs])
  end

  defp initialize_tarjan(opts) do
    num_vertices = Keyword.get(opts, :num_vertices)

    %{
      stack: Stack.new(num_vertices),
      on_stack: Array.new(num_vertices),
      lowest: Array.new(num_vertices),
      sccs: []
    }
  end

  defp tarjan_vertex(%{acc: acc} = state, vertex, :discovered, opts) do
    ((acc && acc) || initialize_tarjan(opts))
    |> tap(fn %{stack: stack, lowest: lowest, on_stack: on_stack} = _acc ->
      Stack.push(stack, vertex)
      Array.put(on_stack, vertex, 1)
      Array.put(lowest, vertex, Dfs.time_in(state, vertex))
    end)
  end

  defp tarjan_vertex(
         %{acc: %{sccs: sccs, lowest: lowest} = acc} = state,
         vertex,
         :processed,
         opts
       ) do
    if Array.get(lowest, vertex) == Dfs.time_in(state, vertex) do
      new_component = tarjan_pop_component(state, vertex)
      Map.put(acc, :sccs, [opts[:component_handler].(new_component, state) | sccs])
    else
      state[:acc]
    end
  end

  defp tarjan_edge(%{acc: %{lowest: lowest} = _acc} = state, from, to, :tree) do
    # lowest[from] <- min(lowest[from], lowest[to])
    Array.put(lowest, from, min(Array.get(lowest, from), Array.get(lowest, to)))

    state[:acc]
  end

  defp tarjan_edge(
         %{acc: %{lowest: lowest, on_stack: on_stack} = _acc} = state,
         from,
         to,
         edge_type
       )
       when edge_type in [:back, :cross] do
    # lowest[v] <- min(lowest[v], num[u])
    if Array.get(on_stack, to) == 1 do
      Array.put(lowest, from, min(Array.get(lowest, from), Dfs.time_in(state, to)))
    end

    state[:acc]
  end

  defp tarjan_edge(state, _from, _to, _event) do
    state[:acc]
  end

  defp tarjan_pop_component(%{acc: %{stack: stack, on_stack: on_stack} = _acc} = _state, vertex) do
    scc = MapSet.new()

    Enum.reduce_while(1..Stack.size(stack), scc, fn _, acc ->
      el = Stack.pop(stack)
      Array.put(on_stack, el, 0)
      acc = MapSet.put(acc, el)
      (el == vertex && {:halt, acc}) || {:cont, acc}
    end)
  end
end
