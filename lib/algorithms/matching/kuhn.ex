defmodule BitGraph.Algorithms.Matching.Kuhn do
  @moduledoc """
  Maximum Matching for bipartite graph (Kuhn algorithm).
  Implementation mostly follows
  https://cp-algorithms.com/graph/kuhn_maximum_bipartite_matching.html

  """

  alias BitGraph.V
  alias BitGraph.Array
  alias Iter.Iterable
  import BitGraph.Common

  @doc """
  `graph` - bipartite graph.
  `left_partition` - list or set of vertices that represent either part of `graph`.

  Options:
  - :fixed_matching (optional) - The edges that have to be in matching. This is a `left_vertex => right vertex`
    , where `left_vertex` is a vertex from `left_partition`
  - :required_size (optional) - The required size of maximum matching. If not reached, algorithm returns `nil`

  Output: map with keys
    - :matching - map of left_vertex => right_vertex
    - :free - unmatched vertices from right partition
  """
  @spec run(BitGraph.t(), MapSet | list(), Keyword.t()) ::
          %{matching: Map.t(), free: MapSet.t()} | nil
  def run(graph, left_partition, opts \\ [])

  def run(graph, left_partition, opts) when is_list(left_partition) do
    run(graph, MapSet.new(left_partition), opts)
  end

  def run(graph, left_partition, opts) when is_struct(left_partition, MapSet) do
    initial_state = initial_state(graph, left_partition, opts)

    Enum.reduce_while(initial_state.left_partition_indices, initial_state, fn lp_vertex_index,
                                                                              state_acc ->
      if state_acc.max_matching_size == get_matching_count(state_acc) do
        {:halt, state_acc}
      else
        {:cont, process_vertex(state_acc, graph, lp_vertex_index)}
      end
    end)
    |> get_matching(graph)
  end

  defp process_vertex(state, graph, vertex_idx) do
    not fixed?(state, vertex_idx) &&
      dfs(graph, vertex_idx, state)
      |> tap(fn success? -> success? && reset_used(state) end) &&
      increase_matching_count(state)

    state
  end

  defp generate_initial_matching(
         %{left_partition_indices: left_partition_indices} = state,
         graph
       ) do
    initial_matching =
      Enum.reduce(left_partition_indices, MapSet.new(), fn lp_vertex_idx, acc ->
        if in_fixed_matching?(state, lp_vertex_idx) do
          acc
        else
          graph
          |> neighbors(lp_vertex_idx)
          |> iterate_initial_matching_impl(lp_vertex_idx, state, acc)
        end
      end)

    Map.put(state, :initially_matched, initial_matching)
  end

  defp iterate_initial_matching_impl(neighbors, lp_vertex_idx, state, acc) do
    iterate(neighbors, acc, fn neighbor, acc2 ->
      if get_match(state, neighbor) == 0 do
        update_match(state, neighbor, lp_vertex_idx)
        increase_matching_count(state)
        {:halt, MapSet.put(acc2, lp_vertex_idx)}
      else
        {:cont, acc2}
      end
    end)
  end

  defp apply_fixed_matching(
         %{left_partition_indices: left_partition_indices} = state,
         graph,
         fixed_matching
       ) do
    indexed_fixed_matching =
      Map.new(fixed_matching || Map.new(), fn {left_vertex, right_vertex} ->
        left_idx = get_vertex_index(graph, left_vertex)

        MapSet.member?(left_partition_indices, left_idx) ||
          throw({:error, {:not_in_left_partition, left_vertex}})

        right_idx = get_vertex_index(graph, right_vertex)

        case get_match(state, right_idx) do
          0 ->
            update_match(state, right_idx, left_idx)

          _already_matched ->
            throw({:error, {:invalid_fixed_matching, {:multiple_matches, right_vertex}}})
        end

        {left_idx, right_idx}
      end)

    increase_matching_count(state, map_size(indexed_fixed_matching))
    Map.put(state, :fixed_matching, indexed_fixed_matching)
  end

  defp fixed?(%{initially_matched: initial_matching} = _state, vertex)
       when is_integer(vertex) do
    # false
    MapSet.member?(initial_matching, vertex)
  end

  defp fixed?(_state, _vertex) do
    false
  end

  defp update_match(%{match: match} = _state, right, left)
       when is_integer(right) and is_integer(left) do
    Array.put(match, right, left)
  end

  defp get_match(%{match: match} = _state, vertex) when is_integer(vertex) do
    Array.get(match, vertex)
  end

  def get_matching_count(state) do
    :counters.get(state.match_count, 1)
  end

  defp increase_matching_count(state, by \\ 1) when is_integer(by) do
    :counters.add(state.match_count, 1, by)
  end

  defp initial_state(graph, left_partition, opts) do
    allocated = BitGraph.max_index(graph)

    %{
      left_partition: left_partition,
      left_partition_indices:
        MapSet.new(left_partition, fn vertex -> get_vertex_index(graph, vertex) end),
      used: Array.new(allocated),
      match: Array.new(allocated),
      match_count: :counters.new(1, [:atomics]),
      max_matching_size: MapSet.size(left_partition),
      required_size: Keyword.get(opts, :required_size)
    }
    |> apply_fixed_matching(graph, Keyword.get(opts, :fixed_matching, Map.new()))
    |> generate_initial_matching(graph)
  end

  defp reset_used(%{used: used} = state) do
    Enum.each(1..Array.size(used), fn idx -> Array.put(used, idx, 0) end)
    state
  end

  defp get_matching(%{required_size: required_size} = state, graph) do
    m_count = get_matching_count(state)

    if is_nil(required_size) || m_count == required_size do
      get_matching_impl(state, graph)
    end
  end

  defp get_matching_impl(
         %{left_partition_indices: left_partition_indices, match: match} = state,
         graph
       ) do
    Enum.reduce_while(
      1..Array.size(match),
      {0, %{matching: Map.new(), free: MapSet.new()}},
      fn candidate_vertex_idx, {c, match_acc} = acc ->
        if MapSet.member?(left_partition_indices, candidate_vertex_idx) do
          ## Ignore left_partition and the vertices in the right partition that are not adjacent to
          ## any of the vertices of left partition.
          {:cont, acc}
        else
          case get_match(state, candidate_vertex_idx) do
            value when value == 0 ->
              {:cont,
               {c,
                (!adjacent_to_left_partition?(graph, candidate_vertex_idx, left_partition_indices) &&
                   match_acc) ||
                  Map.update!(match_acc, :free, fn existing ->
                    MapSet.put(existing, BitGraph.V.get_vertex(graph, candidate_vertex_idx))
                  end)}}

            value ->
              acc =
                {c + 1,
                 put_in(
                   match_acc,
                   [:matching, BitGraph.V.get_vertex(graph, value)],
                   BitGraph.V.get_vertex(graph, candidate_vertex_idx)
                 )}

              {:cont, acc}
          end
        end
      end
    )
    |> elem(1)
  end

  defp in_fixed_matching?(%{fixed_matching: fixed_matching} = _state, vertex) do
    Map.has_key?(fixed_matching, vertex)
  end

  defp get_vertex_index(graph, vertex) do
    V.get_vertex_index(graph, vertex) || no_vertex_exception(vertex)
  end

  defp no_vertex_exception(vertex) do
    throw({:error, {:vertex_not_in_graph, vertex}})
  end

  defp dfs(graph, vertex, %{used: used} = state)
       when is_integer(vertex) do
    if Array.get(used, vertex) == 1 || in_fixed_matching?(state, vertex) do
      false
    else
      Array.put(used, vertex, 1)

      dfs_iterate(graph, neighbors(graph, vertex), state, vertex)
    end
  end

  def dfs_iterate(graph, neighbors, state, vertex) do
    iterate(neighbors, false, iterate_fun(graph, state, vertex))
  end

  def iterate_fun(graph, state, vertex) do
    fn neighbor, _acc ->
      neighbor_match = get_match(state, neighbor)

      if neighbor_match == 0 || dfs(graph, neighbor_match, state) do
        update_match(state, neighbor, vertex)
        {:halt, true}
      else
        {:cont, false}
      end
    end
  end

  defp adjacent_to_left_partition?(graph, vertex_index, left_partition) do
    #!MapSet.disjoint?(left_partition, MapSet.new(neighbors(graph, vertex_index)))
    Iterable.any?(neighbors(graph, vertex_index), fn n -> n in left_partition end)
  end

  defp neighbors(graph, vertex_index) do
    V.neighbors(graph, vertex_index)
  end
end
