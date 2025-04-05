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

  @doc """

    Tarjan SCC

  i – a counter used to assign sequential numbers to the vertices
  num[] – an array of integers holding the vertice numbers, num[v] is the number assigned to v
  lowest[] – an array of integers holding the minimum reachable vertex numbers, lowest[v] is the minimum number of a vertex reachable from v
  s – a stack of vertices used to keep the working set of vertices. s holds all the vertices reachable from the starting vertex. When the algorithm finds an SCC, it will unwind the stack until it gets all the vertices of that SCC

  // GLOBAL VARIABLES
  //    num <- global array of size V initialized to -1
  //    lowest <- global array of size V initialized to -1
  //    s <- global empty stack
  //    i <- 0

  algorithm DFS(G, v):
      // INPUT
      //    G = the graph
      //    v = the current vertex
      // OUTPUT
      //    Vertices reachable from v are processed, their SCCs are reported

      num[v] <- i
      lowest[v] <- num[v]
      i <- i + 1
      visited[v] <- true
      s.push(v)

      for u in G.neighbours[v]:
          if visited[u] = false:
              DFS(G, u)
              lowest[v] <- min(lowest[v], lowest[u])
          else if processed[u] = false:
              lowest[v] <- min(lowest[v], num[u])

      processed[v] <- true

      if lowest[v] = num[v]:
          scc <- an empty set
          sccVertex <- s.pop()

          while sccVertex != v:
              scc.add(sccVertex)
              sccVertex <- s.pop()

          scc.add(sccVertex)

          Process the found scc in the desired way

      return
  """

  def tarjan(graph, component_handler \\ fn component, _state -> component end) do
    graph
    |> Dfs.run(:all,
      process_vertex_fun:
        fn state, v, event ->
          tarjan_vertex(state, v, event, component_handler: component_handler, num_vertices: BitGraph.num_vertices(graph))
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
      i: :counters.new(1, [:atomics]),
      num: Array.new(num_vertices),
      lowest: Array.new(num_vertices),
      sccs: []
    }
  end

  defp tarjan_vertex(%{acc: acc} = _state, vertex, :discovered, opts) do
    (acc && acc || initialize_tarjan(opts))
    |> tap(fn %{stack: stack, i: vertex_num, lowest: lowest, num: num} = _acc ->
      :counters.add(vertex_num, 1, 1)
      Stack.push(stack, vertex)
      last_vertex_num = :counters.get(vertex_num, 1)
      Array.put(num, vertex, last_vertex_num)
      Array.put(lowest, vertex, last_vertex_num)
    end)
  end

  defp tarjan_vertex(%{acc: %{sccs: sccs, lowest: lowest, num: num} = acc} = state, vertex, :processed, opts) do
    if (Array.get(lowest, vertex) == Array.get(num, vertex)) do
      new_component = tarjan_pop_component(state, vertex)
      Map.put(acc, :sccs, [opts[:component_handler].(new_component, state) | sccs])
    else
      state[:acc]
    end
  end

  defp tarjan_edge(%{acc: %{lowest: lowest} = _acc} = state, from, to, :tree) do
    #lowest[from] <- min(lowest[from], lowest[to])
    Array.put(lowest, from,
      min(Array.get(lowest, from), Array.get(lowest, to))
    )

    state[:acc]
  end

  defp tarjan_edge(%{acc: %{lowest: lowest, num: num} = _acc} = state, from, to, :back) do
    #lowest[v] <- min(lowest[v], num[u])
    Array.put(lowest, from,
      min(Array.get(lowest, from), Array.get(num, to))
    )

    state[:acc]
  end

  defp tarjan_edge(state, _from, _to, _event) do
    state[:acc]
  end

  defp tarjan_pop_component(%{acc: %{stack: stack} = _acc} = _state, vertex) do
    scc = MapSet.new()
    Enum.reduce_while(1..Stack.size(stack), scc, fn _, acc ->
      el = Stack.pop(stack)
      acc = MapSet.put(acc, el)
      (el == vertex) && {:halt, acc} || {:cont, acc}
    end)
  end

end
