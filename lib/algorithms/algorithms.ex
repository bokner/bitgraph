defmodule BitGraph.Algorithm do
  alias BitGraph.{Dfs, Array, E, V}
  alias BitGraph.Algorithm.{SCC, Matching.Kuhn}
  alias BitGraph.Traversal.Utils

  @callback init(BitGraph.t(), Keyword.t()) :: any()
  @callback run(BitGraph.t(), Keyword.t()) :: any()
  @callback finalize(BitGraph.t(), any()) :: any()

  ## Run the algorithm represented by implementation module.
  ## If :api option is specified (false by default),
  ## `init/2` is called first. The purpose is to modify the options supplied by the API call
  ## into the options used internally by the algorithm implementation, which is
  ## called by run/2 callback.
  ## finalize/2 callback transforms the results of run/2 back to the form desired by API call.
  ##
  ## Why?
  ## Sometimes we need to run an algorithm alone, without converting input and output of the algoritm
  ## from/to caller's supplied/desired format.
  ## For example, we may want to run bipartite matching on vertex indices several times,
  ## without having to translate the results (matching/free nodes etc.) to vertex labels.
  ## between runs.
  ## More later (planned to be used for cp_solver).
  def run(graph, impl, opts) do
    if Keyword.get(opts, :api, false) do
      impl.init(graph, opts)
      |> then(fn algo_opts ->
        result = impl.run(graph, algo_opts)
        impl.finalize(graph, result)
      end)

    else
      impl.run(graph, opts)
    end
  end

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
      state_acc = Dfs.run(graph, vertices: v, state: state_acc)
      Dfs.acyclic?(state_acc) && {:halt, true} || {:cont, state_acc}
    end)
    |> then(
      fn true -> true
      _ -> false
    end)
  end

  def strongly_connected?(graph, opts \\ []) do
    algo = Keyword.get(opts, :algorithm) || :tarjan
    case algo do
      :kozaraju ->
        SCC.Kozaraju.strongly_connected?(graph, opts)
      :tarjan ->
        SCC.Tarjan.strongly_connected?(graph, opts)
      other -> throw({:scc, :unknown_algo, other})
    end
  end

  def components(graph) do
    Dfs.run(graph, direction: :both, process_vertex_fun:
      fn %{component_top: root, acc: acc} = _state, v  ->
        case acc do
          nil -> %{root => MapSet.new([root, v])}
          existing ->
            Map.update(existing, root, MapSet.new([root]),
            fn component -> MapSet.put(component, v) end)
          end
      end
      )
      |> Map.get(:acc)
      |> Map.values()
  end

  def strong_components(graph, opts \\ []) do
    opts = Keyword.merge(
    [
      algorithm: :kozaraju
    ], Keyword.put(opts, :vertices, Utils.build_vertex_indices(graph, Keyword.get(opts, :vertices, :all))))

    case opts[:algorithm] do
      :tarjan -> SCC.Tarjan.run(graph, opts)
      :kozaraju -> SCC.Kozaraju.run(graph, opts)
      unknown -> throw({:error, {:scc_unknown_algo, unknown}})
    end
  end


  def get_cycle(graph, vertex) when is_integer(vertex) do
    if V.in_degree(graph, vertex) > 0 && V.out_degree(graph, vertex) > 0 do
      Dfs.run(graph, vertices: vertex, process_edge_fun:
        fn state, vertex, _neighbor, :back  ->
              {:stop,
                build_cycle(graph, vertex, state[:parent])
              }
           %{acc: acc} = _state, _vertex, _neighbor, _event ->
              {:next, acc}
        end
      )
      |> Map.get(:acc)
    else
      false
    end
  end

  def bipartite_matching(graph, opts \\ []) do
    {algo, algo_opts} = Keyword.pop(opts, :algorithm, :kuhn)

    case algo do
      :kuhn ->
        run(graph, Kuhn, algo_opts)
      other -> throw({:bipartite_matching, :unknown_algo, other})
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
