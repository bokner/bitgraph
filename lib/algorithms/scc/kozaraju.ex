defmodule BitGraph.Algorithms.SCC.Kozaraju do
  alias BitGraph.Dfs

  ## Kozaraju's SCC algorithm
  def run(graph,
      opts \\ []
    ) do
      BitGraph.num_vertices(graph) == 0 && [] ||
    (
    component_handler =
      opts
      |> Keyword.get(:component_handler, fn component, _acc -> component end)
      |> wrap_component_handler()

    graph
    |> Dfs.run(opts)
    |> Dfs.order(:out, :desc)
    |> Enum.reduce({nil, nil}, fn v, {state_acc, components_acc} ->
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
        component && component_handler.(component, components_acc) || components_acc
      }
    end)
    |> elem(1))
  end

  def strongly_connected?(graph, opts \\ []) do
    try do
      component_handler =  fn component, _acc ->
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

  defp wrap_component_handler({handler_fun, initial_value}) do
    wrap_component_handler(handler_fun, initial_value)
  end

  defp wrap_component_handler(handler_fun, initial_value \\ []) when is_function(handler_fun, 2) do
      fn component, acc ->
        handler_fun.(component, acc || initial_value)
      end
  end

end
