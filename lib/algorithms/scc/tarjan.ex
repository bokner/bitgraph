defmodule BitGraph.Algorithms.SCC.Tarjan do

  alias BitGraph.{Dfs, Array, Stack}
  @doc """
    Tarjan algo for SCC.
    Roughly follows https://blog.heycoach.in/tarjans-algorithm-in-graph-theory/
  """

  def run(graph,
    component_handler \\ fn component, _state -> component end,
    opts \\ []
    ) when is_function(component_handler, 2) do
    graph
    |> Dfs.run(
      process_vertex_fun: fn state, v, event ->
        tarjan_vertex(state, v, event,
          component_handler: component_handler,
          num_vertices: BitGraph.num_vertices(graph),
          on_dag_handler: opts[:on_dag_handler]
        )
      end,
      process_edge_fun: &tarjan_edge/4,
      edge_process_order: :postorder
    )
    |> get_in([:acc, :sccs])
  end

  def strongly_connected?(graph) do
    try do
      run(graph,
      fn component, _dfs_state ->
        throw({:single_scc?, component && (MapSet.size(component) == BitGraph.num_vertices(graph))})

        end,

        on_dag_handler: fn vertex ->
          throw({:error, :dag, vertex})
        end)
    catch
      {:single_scc?, res} -> res
      {:error, :dag, _vertex} -> false
    end

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
    ## Pre-process based on whether the loop occurs after
    ## processing this vertex.
    ## Used for cases where we want to shortcut processing
    ## (for instance, figure if a graaph is strongly connected)
    acc = case opts[:on_dag_handler] do
      nil -> acc
      on_dag_handler when state.dag ->
        on_dag_handler.(vertex)
      _ -> acc
    end

    if Array.get(lowest, vertex) == Dfs.time_in(state, vertex) do
      new_component = tarjan_pop_component(state, vertex)
      Map.put(acc, :sccs, [opts[:component_handler].(new_component, state) | sccs])
    else
      acc
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
