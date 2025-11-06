defmodule BitGraph.Algorithm.Search.AStar do
  @doc """
    A* algorithm.
    Finds the shortest path in graph from `start` vertex to `goal` vertex.
    `dist_fun` is a function that takes 2 vertex indices and returns the distance between them.
    `h` is a "heuristic", a function h(n) that estimates the cost to reach goal vertex from node n.
  """
  alias InPlace.PriorityQueue, as: Q
  alias InPlace.Array
  import BitGraph
  alias BitGraph.V

  @infinity :infinity

  def run(graph, start_vertex, goal_vertex, opts)
      when is_integer(start_vertex) and is_integer(goal_vertex) do
    dist_fun = Keyword.get(opts, :dist_fun, fn _v1, _v2 -> 1 end)
    h_fun = Keyword.get(opts, :h_fun, fn _vertex -> 0 end)
    run(graph, start_vertex, goal_vertex, h_fun, dist_fun)
  end

  def run(graph, start_vertex, goal_vertex, h_fun, dist_fun)
      when is_integer(start_vertex) and is_integer(goal_vertex) and
             is_function(h_fun, 1) and is_function(dist_fun, 2) do
    instance = init(graph, start_vertex, goal_vertex, h_fun, dist_fun)

    iterate(graph, instance)
    |> finalize()
  end

  defp init(graph, start_vertex, goal_vertex, h_fun, dist_fun) do
    n_vertices = num_vertices(graph)
    p_queue = Q.new(n_vertices)
    Q.insert(p_queue, start_vertex, {h_fun.(start_vertex), 0})
    path = Array.new(n_vertices)
    # Array.put(g_score, 0, 0)
    # Array.put(f_score, 0, h_fun.(start_vertex))
    %{
      num_vertices: n_vertices,
      start: start_vertex,
      goal: goal_vertex,
      open_set: p_queue,
      g_score: Map.new([{start_vertex, 0}]),
      path: path,
      h_fun: h_fun,
      dist_fun: dist_fun
    }
  end

  defp iterate(
         graph,
         %{
           goal: goal,
           path: path,
           open_set: open_set,
           g_score: g_score_map,
           h_fun: h_fun,
           dist_fun: dist_fun
         } = state
       ) do
    if Q.empty?(open_set) do
      :failure
    else
      {vertex, _min_fscore} = Q.extract_min(open_set)

      if vertex == goal do
        reconstruct_path(path)
      else
        g_score = Map.get(g_score_map, vertex)

        updated_g_scores =
          Enum.reduce(V.out_neighbors(graph, vertex), g_score_map, fn neighbor, g_score_acc ->
            ### Pseudocode
            tentative_g_score = g_score + dist_fun.(vertex, neighbor)

            if tentative_g_score < Map.get(g_score_acc, neighbor, @infinity) do
              #  This path to neighbor is better than any previous one. Record it!
              Array.put(path, neighbor, vertex)
              Q.insert(
                open_set,
                neighbor,
                {tentative_g_score + h_fun.(neighbor), tentative_g_score}
              )

              Map.put(g_score_acc, neighbor, tentative_g_score)
            else
              g_score_acc
            end
          end)

        iterate(graph, Map.put(state, :g_score, updated_g_scores))
      end
    end
  end

  defp reconstruct_path(path) do
    path
  end

  defp finalize(result) do
    :todo
  end
end
