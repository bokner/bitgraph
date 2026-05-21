defmodule BitGraph.Algorithm.Search.AStar do
  @doc """
    A* algorithm.
    Finds the shortest path in graph from `start` vertex to `goal` vertex.
    `dist_fun` is a function that takes 2 vertex indices and returns the distance between them.
    `h` is a "heuristic", a function h(n) that estimates the cost to reach goal vertex from node n.
  """
  alias InPlace.PriorityQueue, as: Q
  #import BitGraph
  alias BitGraph.V

  @behaviour BitGraph.Algorithm

  @infinity :infinity

  @impl true
  def run(graph, opts) do
    start_vertex = Keyword.fetch!(opts, :start)
    goal_vertex = Keyword.fetch!(opts, :goal)
    opts = Keyword.merge(default_opts(), opts)
    dist_fun = Keyword.get(opts, :dist_fun, fn _v1, _v2 -> 1 end)
    h_fun = Keyword.get(opts, :h_fun, fn _vertex -> 0 end)
    run(graph, start_vertex, goal_vertex, h_fun, dist_fun)
  end

  @impl true
  def preprocess(graph, opts) do
    start_vertex = Keyword.fetch!(opts, :start)
    goal_vertex = Keyword.fetch!(opts, :goal)

    Keyword.merge(default_opts(), opts)
    |> Keyword.update!(:dist_fun, fn original_fun ->
        fn v1, v2 -> original_fun.(
          V.get_vertex(graph, v1),
          V.get_vertex(graph, v2))
        end
    end)
    |> Keyword.update!(:h_fun, fn original_fun -> fn v -> original_fun.(V.get_vertex(graph, v)) end end)
    |> Keyword.put(:start, V.get_vertex_index(graph, start_vertex))
    |> Keyword.put(:goal, V.get_vertex_index(graph, goal_vertex))
  end

  @impl true
  def postprocess(graph, path) do
    Enum.map(path, fn vertex_index -> V.get_vertex(graph, vertex_index) end)
  end

  defp default_opts() do
    [
      dist_fun: fn _v1, _v2 -> 1 end,
      h_fun: fn _v -> 0 end
    ]
  end

  def run(graph, start_vertex, goal_vertex, h_fun, dist_fun)
      when is_integer(start_vertex) and is_integer(goal_vertex) and
             is_function(h_fun, 1) and is_function(dist_fun, 2) do
    instance = init(graph, start_vertex, goal_vertex, h_fun, dist_fun)

    iterate(graph, instance)
    |> finalize()
  end

  defp init(graph, start_vertex, goal_vertex, h_fun, dist_fun) do
    n_vertices = BitGraph.num_vertices(graph)
    p_queue = Q.new(n_vertices)
    Q.insert(p_queue, start_vertex, apply_h_fun(h_fun, start_vertex))
    path = Map.new()
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

  defp apply_h_fun(h_fun, vertex) do
    ## Default to 0 if heuristic for the vertex is not defined
    h_fun.(vertex) || 0
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
    case Q.extract_min(open_set) do
      nil ->
        :failure

      {vertex, _min_fscore} when vertex == goal ->
        {:ok, reconstruct_path(vertex, path)}

      {vertex, _min_fscore} ->
        vertex_g_score = Map.get(g_score_map, vertex)

        {updated_path, updated_g_scores} =
          Enum.reduce(
            V.out_neighbors(graph, vertex),
            {path, g_score_map},
            fn neighbor, {path_acc, g_score_acc} = acc ->
              tentative_g_score = vertex_g_score + dist_fun.(vertex, neighbor)

              if tentative_g_score < Map.get(g_score_acc, neighbor, @infinity) do
                #  This path to neighbor is better than any previous one. Record it!
                Q.insert(
                  open_set,
                  neighbor,
                  tentative_g_score + apply_h_fun(h_fun, neighbor)
                )

                {
                  Map.put(path_acc, neighbor, vertex),
                  Map.put(g_score_acc, neighbor, tentative_g_score)
                }
              else
                acc
              end
            end
          )

        iterate(
          graph,
          state
          |> Map.put(:g_score, updated_g_scores)
          |> Map.put(:path, updated_path)
        )
    end
  end

  defp reconstruct_path(vertex, path) do
    reconstruct_path(vertex, path, [vertex])
  end

  defp reconstruct_path(v, path, acc) do
    case Map.get(path, v) do
      nil -> acc
      next ->
        reconstruct_path(next, path, [next | acc])
    end
  end

  defp finalize(result) do
    case result do
      {:ok, path} ->
        path
      :failure ->
        :failure
    end
  end

end
