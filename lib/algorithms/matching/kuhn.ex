defmodule BitGraph.Algorithms.Matching.Kuhn do
  @moduledoc """
  Maximum Matching for bipartite graph (Kuhn algorithm).
  """

  alias BitGraph.{V}
  alias BitGraph.Array

  def run(graph, left_partition, opts \\ [])

  def run(graph, left_partition, opts) when is_list(left_partition) do
    run(graph, MapSet.new(left_partition), opts)
  end

  def run(graph, left_partition, opts) when is_struct(left_partition, MapSet) do
    Enum.reduce(left_partition, initial_state(graph, left_partition, opts),
      fn lp_vertex, state_acc ->
        if dfs(graph, V.get_vertex_index(graph, lp_vertex), reset_used(state_acc)) do
          increase_matching_count(state_acc)
        end
        state_acc
      end
    )
    |> get_matching(graph)
  end

  defp generate_initial_matching(_graph, _left_partition) do
    %{}
  end

  defp increase_matching_count(state) do
    :counters.add(state.match_count, 1, 1)
  end

  defp initial_state(graph, left_partition, _opts) do
    %{
      used: Array.new(BitGraph.num_vertices(graph)),
      match: Array.new(BitGraph.num_vertices(graph)),
      match_count: :counters.new(1, [:atomics]),
      initial_matching: generate_initial_matching(graph, left_partition)
    }
  end

  defp reset_used(%{used: used} = state) do
    Enum.each(1..Array.size(used), fn idx -> Array.put(used, idx, 0) end)
    state
  end

  defp get_matching(%{match: match, match_count: match_count} = _state, graph) do
    m_count = :counters.get(match_count, 1)
    Enum.reduce_while(1..Array.size(match), {0, Map.new()},
      fn idx, {c, match_acc} = acc ->
        case Array.get(match, idx) do
          value when value == 0 -> {:cont, acc}
          value ->
            acc = {c + 1, Map.put(match_acc,
              BitGraph.V.get_vertex(graph, value),
              BitGraph.V.get_vertex(graph, idx))}
            if c + 1 == m_count do
              {:halt, acc}
            else
              {:cont, acc}
            end
      end
      end)
      |> elem(1)
  end


  defp dfs(graph, vertex, %{used: used, match: match} = state) when is_integer(vertex) do
    if Array.get(used, vertex) == 1 do
      false
    else
      Array.put(used, vertex, 1)
      Enum.reduce_while(BitGraph.E.neighbors(graph, vertex), false,
        fn neighbor, _new_match? ->
          neighbor_match = Array.get(match, neighbor)
          if neighbor_match == 0 || dfs(graph, neighbor_match, state) do
            Array.put(match, neighbor, vertex)
            {:halt, true}
          else
            {:cont, false}
          end
      end)
    end
  end
end
