defmodule BitGraph.Algorithm.Search.AStar do
  @doc """
    A* algorithm.
    Finds the shortest path in graph from `start` vertex to `goal` vertex.
    `dist` is a matrix of distances between vertices.
    `h` is a "heuristic", a function h(n) that estimates the cost to reach goal from node n.
  """
  alias InPlace.PriorityQueue, as: Q
  alias InPlace.Array
  import BitGraph
  alias BitGraph.V

  def run(graph, start, goal, dist, h) when is_integer(start) and is_integer(goal)
    and is_function(h, 1) do
      {open_set, g_score, f_score} = init(graph, start, h)
      iterate(graph, goal, open_set, g_score, f_score, h, dist, Map.new())
      |> finalize()
  end

  defp init(graph, start, h) do
      n_vertices = num_vertices(graph)
      p_queue = Q.new(n_vertices)
      Q.insert(p_queue, start, 0)
      g_score = Array.new(n_vertices)
      f_score = Array.new(n_vertices)
      Array.put(g_score, 0, 0)
      Array.put(f_score, 0, h.(start))
      {p_queue, g_score, f_score}
  end

  defp iterate(graph, goal, open_set, g_score, f_score, h, dist, path) do
    if Q.empty?(open_set) do
      :failure
    else
      {vertex, _priority} = Q.extract_min(open_set)
      if vertex == goal do
        path
      else
        Enum.reduce(V.out_neighbors(graph, vertex), path, fn neighbor, acc ->
          ### Pseudocode
            # tentative_gScore := gScore[current] + d(current, neighbor)
            # if tentative_gScore < gScore[neighbor]
            #     // This path to neighbor is better than any previous one. Record it!
            #     cameFrom[neighbor] := current
            #     gScore[neighbor] := tentative_gScore
            #     fScore[neighbor] := tentative_gScore + h(neighbor)
            #     if neighbor not in openSet
            #         openSet.add(neighbor)
        end)
      end
    end
  end

  defp finalize(result) do
    :todo
  end

end
