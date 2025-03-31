defmodule BitGraph.Algorithms.SCC do
  alias BitGraph.{Dfs, Array, Stack}

  ## Kozaraju's SCC algorithm
  def kozaraju(graph, component_handler \\ fn component, _state -> component end) do
    graph
    |> Dfs.run()
    |> Dfs.order(:out, :desc)
    |> Enum.reduce({nil, []}, fn v, {state_acc, components_acc} ->
      state = Dfs.run(graph, v,
        direction: :reverse,
        state: state_acc,
        process_vertex_fun: fn %{acc: acc} = _state, vertex ->
          MapSet.put(acc || MapSet.new(), vertex)
        end
      )
      component = state[:acc]

      {Map.put(state, :acc, nil),
        component && [component_handler.(component, state) | components_acc] || components_acc}
    end)
    |> elem(1)
  end

  def tarjan_scc(graph, component_handler \\ fn component, _state -> component end) do
    graph
    |> Dfs.run(:all,
      process_vertex_fun:
        fn state, v, event ->
          tarjan_vertex(state, v, event, num_vertices: BitGraph.num_vertices(graph))
        end,
      process_edge_fun: &tarjan_edge/4
    )
  end

  defp initialize_tarjan(opts) do
    num_vertices = Keyword.get(opts, :num_vertices)
    %{stack: Stack.new(num_vertices),
      components_found: 0,
      low:
        Array.new(num_vertices)
        |> tap(fn ref ->
          for i <- 1..num_vertices do
            Array.put(ref, i, i)
          end
        end),
      scc: Array.new(num_vertices)
    }
  end

  defp tarjan_vertex(%{acc: acc} = state, vertex, :discovered, opts) do
    #IO.inspect({:discovered, vertex}, label: :tarjan)
    (acc && acc || initialize_tarjan(opts))
    |> tap(fn %{stack: stack} = _acc ->
      Stack.push(stack, vertex)
    end)
  end

  defp tarjan_vertex(%{acc: %{low: low} = _acc} = state, vertex, :processed, _opts) do
    IO.inspect({:processed, vertex}, label: :tarjan)
    if (Array.get(low, vertex) == vertex) do
      tarjan_pop_component(state, vertex)
    end

    low_vertex = Array.get(low, vertex)
    low_vertex_parent = Dfs.parent(state, low_vertex)
    if Dfs.time_in(state, vertex) > Dfs.time_in(state, low_vertex) do
      Array.put(low, low_vertex_parent, low_vertex)
    end

    state[:acc]
  end

  defp tarjan_edge(%{acc: %{scc: scc} = _acc} = state, from, to, :cross) do
    IO.inspect({from, to, :cross}, label: :tarjan)
    if Array.get(scc, from) == 0 do
      tarjan_update_low(state, from, to)
    end

    state[:acc]
  end

  defp tarjan_edge(state, from, to, :back) do
    IO.inspect({from, to, :back}, label: :tarjan)
    tarjan_update_low(state, from, to)
    state[:acc]
  end

  defp tarjan_edge(state, from, to, event) do
    IO.inspect({from, to, event}, label: :tarjan)
    state[:acc]
  end

  defp tarjan_update_low(%{acc: %{low: low} = _acc} = state, from, to) do
    if Dfs.time_in(state, to) < Dfs.time_in(state, Array.get(low, from)) do
      Array.put(low, from, to)
    end
  end

  defp tarjan_pop_component(%{acc: %{stack: stack} = _acc} = state, vertex) do
    IO.inspect({"pop component", vertex}, label: :pop_component)
    IO.inspect(Array.to_list(stack), label: :stack)
  end

end
