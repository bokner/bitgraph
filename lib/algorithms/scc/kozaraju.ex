defmodule BitGraph.Algorithm.SCC.Kozaraju do
  alias BitGraph.{Dfs, Algorithm}

  import BitGraph.Algorithm.SCC.Utils
  import BitGraph.Algorithm

  @behaviour Algorithm

  ## Kozaraju's SCC algorithm
  @impl true
  def run(graph,
      opts \\ []
    ) do
      BitGraph.num_vertices(graph) == 0 && [] ||
    (
    component_handler =
      opts
      |> Keyword.get(:component_handler, {fn component, acc -> [component | acc] end, []})
      |> wrap_component_handler()

    graph
    |> dfs(opts)
    |> Dfs.order(:out, :desc)
    |> Enum.reduce({nil, nil}, fn v, {state_acc, components_acc} ->
      state =
        dfs(graph, vertices: v,
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

  @impl true
  def preprocess(graph, opts) do
    Dfs.preprocess(graph, opts)
  end

  @impl true
  def postprocess(_graph, res) do
    res
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

end
