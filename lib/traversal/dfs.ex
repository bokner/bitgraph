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
    initial_state = Keyword.get(opts, :state) || init_dfs(graph, hd(vertices), opts)
    Enum.reduce(vertices, initial_state, fn vertex, state_acc ->
      if vertex_color(state_acc, vertex) == @white_vertex do
        dfs_impl(graph, vertex, state_acc)
      else
        state_acc
      end
    end)
  end

  defp init_dfs(graph, root, opts) do
    num_vertices = BitGraph.num_vertices(graph)
    %{
      root: root,
      reverse_dfs: Keyword.get(opts, :reverse_dfs, false),
      reduce_fun: Keyword.get(opts, :reduce_fun, default_reduce_fun())
      |> normalize_reduce_fun(),
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

  defp dfs_impl(graph, vertex, %{reverse_dfs: reverse_dfs} = state)
    when is_integer(vertex) do
      time = inc_timer(state)
      Array.put(state[:time_in], vertex, time)
      Array.put(state[:color], vertex, @gray_vertex)
      {_action, initial_state} = apply_reduce(state, vertex)
      Enum.reduce_while(vertex_neighbors(graph, vertex, reverse_dfs), initial_state, fn
        neighbor, state_acc ->
          Array.put(state[:parent], neighbor, vertex)
          case vertex_color(state, neighbor) do
            @black_vertex -> state_acc
            @gray_vertex  ->
              on_loop(neighbor, state_acc)
            @white_vertex ->
              dfs_impl(graph, neighbor, state_acc)
          end
          |> to_reduce_while_result()
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
    fn %{acc: _acc} = _state, _vertex, _loop? ->
      nil
    end
  end

  defp normalize_reduce_fun(reduce_fun) when is_function(reduce_fun, 2) do
    fn state, vertex, _loop? -> reduce_fun.(state, vertex) end
  end

  defp normalize_reduce_fun(reduce_fun) when is_function(reduce_fun, 3) do
    reduce_fun
  end

  defp apply_reduce(%{reduce_fun: reduce_fun} = state, vertex, opts \\ []) when is_function(reduce_fun, 3) do
    {next_action, acc} = case reduce_fun.(state, vertex, Keyword.get(opts, :loop, false)) do
      {:next, acc} -> {:next, acc}
      {:stop, acc} -> {:stop, acc}
      acc -> {:next, acc}
    end
    {next_action, Map.put(state, :acc, acc)}
  end

  defp to_reduce_while_result(result) do
    case result do
      {:next, acc} -> {:cont, acc}
      {:stop, acc} -> {:halt, acc}
      acc -> {:cont, acc}
    end
  end

  defp vertex_neighbors(graph, vertex, reverse_dfs) do
    reverse_dfs && E.in_neighbors(graph, vertex) || E.out_neighbors(graph, vertex)
  end

  def acyclic?(state) do
    state.dag
  end

  ## The vertex has closed the loop
  defp on_loop(vertex, state) do
    Map.put(state, :dag, false)
    |> apply_reduce(vertex, loop: true)
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
