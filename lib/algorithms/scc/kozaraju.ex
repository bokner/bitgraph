defmodule BitGraph.Algorithms.SCC.Kozaraju do
  alias BitGraph.Dfs

  ## Kozaraju's SCC algorithm
  def run(graph,
      opts \\ []
    ) do
      BitGraph.num_vertices(graph) == 0 && [] ||
    (
    component_handler = Keyword.get(opts, :component_handler, fn component, _state -> component end)

    graph
    |> Dfs.run(opts)
    |> Dfs.order(:out, :desc)
    |> Enum.reduce({nil, []}, fn v, {state_acc, components_acc} ->
      state =
        Dfs.run(graph, vertices: v,
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
    |> elem(1))
  end

  def strongly_connected?(graph, opts \\ []) do
    try do
      component_handler =  fn component, _dfs_state ->
        throw({:single_scc?, component && (MapSet.size(component) == BitGraph.num_vertices(graph))})
      end

      run(graph,

        Keyword.merge(opts,
        component_handler: component_handler,
        process_vertex_fun: fn(state, vertex, event) ->
          event == :processed && state.dag && throw({:error, :dag, vertex}) || state[:acc] end)
      )
    catch
      {:single_scc?, res} -> res
      {:error, :dag, _vertex} -> false
    end

  end

end
