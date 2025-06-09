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
    Enum.reduce_while(
      left_partition,
      initial_state(graph, left_partition, opts),
      fn lp_vertex, state_acc ->
        if state_acc.max_matching_size == get_matching_count(state_acc) do
          {:halt, state_acc}
        else
          {:cont, process_vertex(state_acc, graph, get_vertex_index(graph, lp_vertex))}
        end
      end
    )
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
         %{left_partition: left_partition, neighbor_finder: neighbor_finder} = state,
         graph
       ) do
    initial_matching =
      Enum.reduce(left_partition, MapSet.new(), fn lp_vertex, acc ->
        vertex_idx = get_vertex_index(graph, lp_vertex)

        if in_fixed_matching?(state, vertex_idx) do
          acc
        else
          Enum.reduce_while(BitGraph.E.neighbors(graph, vertex_idx, neighbor_finder), acc, fn neighbor, acc2 ->
            if get_match(state, neighbor) == 0 do
              update_match(state, neighbor, vertex_idx)
              increase_matching_count(state)
              {:halt, MapSet.put(acc2, vertex_idx)}
            else
              {:cont, acc2}
            end
          end)
        end
      end)

    Map.put(state, :initially_matched, initial_matching)
  end

  defp apply_fixed_matching(%{left_partition: left_partition} = state, graph, fixed_matching) do
    indexed_fixed_matching =
      Map.new(fixed_matching || Map.new(), fn {left_vertex, right_vertex} ->
        MapSet.member?(left_partition, left_vertex) ||
          throw({:error, {:not_in_left_partition, left_vertex}})

        left_idx = get_vertex_index(graph, left_vertex)
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
    num_vertices = BitGraph.num_vertices(graph)

    %{
      left_partition: left_partition,
      used: Array.new(num_vertices),
      match: Array.new(num_vertices),
      match_count: :counters.new(1, [:atomics]),
      max_matching_size: MapSet.size(left_partition),
      required_size: Keyword.get(opts, :required_size),
      neighbor_finder: Keyword.get(opts, :neighbor_finder, BitGraph.E.default_neighbor_finder())
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

  defp get_matching_impl(%{left_partition: left_partition, match: match} = state, graph) do
    Enum.reduce_while(
      1..Array.size(match),
      {0, %{matching: Map.new(), free: MapSet.new()}},
      fn idx, {c, match_acc} = acc ->
        candidate_vertex = BitGraph.V.get_vertex(graph, idx)

        if MapSet.member?(left_partition, candidate_vertex) do
          ## Ignore left_partition
          {:cont, acc}
        else
          case get_match(state, idx) do
            value when value == 0 ->
              {:cont,
               {c,
                Map.update!(match_acc, :free, fn existing ->
                  MapSet.put(existing, candidate_vertex)
                end)}}

            value ->
              acc =
                {c + 1,
                 put_in(
                   match_acc,
                   [:matching, BitGraph.V.get_vertex(graph, value)],
                   candidate_vertex
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

  defp dfs(graph, vertex, %{used: used, neighbor_finder: neighbor_finder} = state)
       when is_integer(vertex) do
    if Array.get(used, vertex) == 1 || in_fixed_matching?(state, vertex) do
      false
    else
      Array.put(used, vertex, 1)

      Enum.reduce_while(BitGraph.E.neighbors(graph, vertex, neighbor_finder), false, fn neighbor, _new_match? ->
        neighbor_match = get_match(state, neighbor)

        if neighbor_match == 0 || dfs(graph, neighbor_match, state) do
          update_match(state, neighbor, vertex)
          {:halt, true}
        else
          {:cont, false}
        end
      end)
    end
  end
end
