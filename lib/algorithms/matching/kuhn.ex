defmodule BitGraph.Algorithms.Matching.Kuhn do
  @moduledoc """
  Maximum Matching for bipartite graph (Kuhn algorithm).
  Implementation mostly follows
  https://cp-algorithms.com/graph/kuhn_maximum_bipartite_matching.html

  """

  alias BitGraph.{V}
  alias BitGraph.Array

  @doc """
  `graph` - bipartite graph.
  `left_partition` list or set of vertices that represent either part of `graph`.

  Options:
  - :fixed_matching - The edges that have to be in matching. This is a `left_vertex => right vertex`
    , where `left_vertex` is a vertex from `left_partition`
  """
  def run(graph, left_partition, opts \\ [])

  def run(graph, left_partition, opts) when is_list(left_partition) do
    run(graph, MapSet.new(left_partition), opts)
  end

  def run(graph, left_partition, opts) when is_struct(left_partition, MapSet) do
    Enum.reduce(left_partition, initial_state(graph, left_partition, opts),
      fn lp_vertex, state_acc ->
        case V.get_vertex_index(graph, lp_vertex) do
          nil -> no_vertex_exception(lp_vertex)
          vertex_idx ->
            process_vertex(state_acc, graph, vertex_idx)
          end
      end
    )
    |> get_matching(graph)
  end

  defp process_vertex(state, graph, vertex_idx) do
    (not assigned?(state, vertex_idx))
    && dfs(graph, vertex_idx, reset_used(state))
    && increase_matching_count(state)
    state
  end

  defp generate_initial_matching(state, graph, left_partition) do
    # mt.assign(k, -1);
    # vector<bool> used1(n, false);
    # for (int v = 0; v < n; ++v) {
    #     for (int to : g[v]) {
    #         if (mt[to] == -1) {
    #             mt[to] = v;
    #             used1[v] = true;
    #             break;
    #         }
    #     }
    # }

    #fixed_matching
    Map.put(state, :initial_matching, %{})
  end

  defp apply_fixed_matching(%{match: match} = state, graph, left_partition, fixed_matching) do
    ## Fixed matching is a map left_vertex => right_vertex

    indexed_fixed_matching = Map.new(fixed_matching || Map.new(), fn {left_vertex, right_vertex} ->
      MapSet.member?(left_partition, left_vertex) || throw({:error, {:not_in_left_partition, left_vertex}})
      left_idx = get_vertex_index(graph, left_vertex)
      right_idx = get_vertex_index(graph, right_vertex)
      Array.put(match, right_idx, left_idx)
      {left_idx, right_idx}
    end)

    increase_matching_count(state, map_size(indexed_fixed_matching))
    Map.put(state, :fixed_matching, indexed_fixed_matching)
  end

  defp assigned?(%{initial_matching: initial_matching} = _state, vertex) do
    Map.has_key?(initial_matching, vertex)
  end



  defp increase_matching_count(state, by \\ 1) do
    :counters.add(state.match_count, 1, by)
  end

  defp initial_state(graph, left_partition, opts) do
    %{
      used: Array.new(BitGraph.num_vertices(graph)),
      match: Array.new(BitGraph.num_vertices(graph)),
      match_count: :counters.new(1, [:atomics])
    }
    |> apply_fixed_matching(graph, left_partition, Keyword.get(opts, :fixed_matching))
    |> generate_initial_matching(graph, left_partition)
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

  defp fixed_in_matching(fixed_matching, vertex) do
    Map.has_key?(fixed_matching, vertex)
  end

  defp get_vertex_index(graph, vertex) do
    V.get_vertex_index(graph, vertex) || no_vertex_exception(vertex)
  end

  defp no_vertex_exception(vertex) do
    throw({:error, {:vertex_not_in_graph, vertex}})
  end

  defp dfs(graph, vertex, %{used: used, match: match, fixed_matching: fixed_matching} = state) when is_integer(vertex) do
    if Array.get(used, vertex) == 1 || fixed_in_matching(fixed_matching, vertex) do
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
