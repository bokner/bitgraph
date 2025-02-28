defmodule BitGraph.Dfs do
  alias BitGraph.E
  alias BitGraph.Array

  @moduledoc """
  Depth-first search.
  Implementation roughly follows
  https://cp-algorithms.com/graph/depth-first-search.html
  """

  @white_vertex 0
  @gray_vertex 1
  @black_vertex 2

  def run(graph, vertices \\ :all, opts \\ [])

  def run(graph, :all, opts) do
    run(graph, BitGraph.vertex_indices(graph), opts)
  end

  def run(graph, root, opts) when is_integer(root) do
    run(graph, [root], opts)
  end

  def run(graph, vertices, opts) when is_list(vertices) do
    reduce_fun = Keyword.get(opts, :reduce_fun, default_reduce_fun())
    reverse_dfs? = Keyword.get(opts, :reverse_dfs, false)
    initial_state = Keyword.get(opts, :state) || init_dfs(graph, hd(vertices))

    Enum.reduce(vertices, initial_state, fn vertex, state_acc ->
      if vertex_color(state_acc, vertex) == @white_vertex do
        dfs_impl(graph, vertex, nil, state_acc, reduce_fun, reverse_dfs?)
      else
        state_acc
      end
    end)
  end

  defp init_dfs(graph, root) do
    num_vertices = BitGraph.num_vertices(graph)
    %{
      root: root,
      dag: true,
      timer: :counters.new(1, [:atomics]),
      ## Color (white, black or gray)
      #### white if the vertex hasn't been visited,
      #### black, if the vertex was visited
      #### gray,  if dfs has already exited the vertex.
      ####
      color: Array.new(num_vertices),
      ## Time of dfs entering the vertex
      time_in: Array.new(num_vertices),
      ## Time of dfs exiting vertex
      time_out: Array.new(num_vertices),
      parent: Array.new(num_vertices),
      acc: nil
    }
  end

  defp dfs_impl(graph, vertex, parent, state, reduce_fun, reverse_dfs?)
    when is_integer(vertex) and is_function(reduce_fun, 3) do
      time = inc_timer(state)
      Array.put(state[:time_in], vertex, time)
      parent && Array.put(state[:parent], vertex, parent)
      Array.put(state[:color], vertex, @gray_vertex)
      neighbors = reverse_dfs? && E.in_neighbors(graph, vertex) || E.out_neighbors(graph, vertex)
      initial_state = apply_reduce(graph, vertex, state, reduce_fun)
      Enum.reduce(neighbors, initial_state, fn
        neighbor, state_acc ->
          case vertex_color(state, neighbor) do
            @gray_vertex -> set_acyclic(state_acc)
            @black_vertex -> state_acc
            @white_vertex ->
              dfs_impl(graph, neighbor, vertex,
                apply_reduce(
                  graph, neighbor, state_acc, reduce_fun),
                  reduce_fun, reverse_dfs?)
          end
      end)
      |> tap(fn _ ->
      time = inc_timer(state)
      Array.put(state[:time_out], vertex, time)
      Array.put(state[:color], vertex, @black_vertex)
      end)
  end

  defp inc_timer(%{timer: timer} = _state) do
    :ok = :counters.add(timer, 1, 1)
    :counters.get(timer, 1)
  end

  def vertex_color(state, vertex) do
    Array.get(state[:color], vertex)
  end

  defp default_reduce_fun() do
    fn _graph, _vertex, %{acc: _acc} = _state ->
      nil
    end
  end

  defp apply_reduce(graph, vertex, state, reduce_fun) when is_function(reduce_fun, 3) do
    acc = reduce_fun.(graph, vertex, state)
    Map.put(state, :acc, acc)
  end

  def acyclic?(state) do
    state.dag
  end

  defp set_acyclic(state) do
    Map.put(state, :dag, false)
  end

  def order(state, :in, order) when order in [:desc, :asc] do
    order_impl(state[:time_in], order)
  end

  def order(state, :out, order) when order in [:desc, :asc] do
    order_impl(state[:time_out], order)
  end

  defp order_impl(arr_ref, order) do
    arr_ref
    |> Array.to_list()
    |> Enum.with_index(1)
    |> Enum.sort(order)
    |> Enum.map(fn {_time_out, vertex_idx} -> vertex_idx end)
  end
end
