defmodule BitGraph.Dfs do
  alias BitGraph.{V, E}
  alias BitGraph.Array

  @moduledoc """
  Depth-first search.
  Implementation roughly follows
  https://cp-algorithms.com/graph/depth-first-search.html
  """

  @white_vertex 0
  @black_vertex 1
  @gray_vertex 2

  def run(graph, root \\ 1, opts \\ [])

  def run(graph, root, opts) when is_integer(root) do
    run(graph, [root], opts)
  end

  def run(graph, vertices, opts) when is_list(vertices) do
    reduce_fun = Keyword.get(opts, :reduce_fun, default_reduce_fun())
    reverse_dfs? = Keyword.get(opts, :reverse_dfs, false)

    Enum.reduce(vertices, init_dfs(graph, hd(vertices)), fn vertex, state_acc ->
      if vertex_color(state_acc, vertex) == @white_vertex do
        dfs_impl(graph, vertex, nil, state_acc, reduce_fun, reverse_dfs?)
      else
        state_acc
      end
    end)
  end

  def dfs(graph, root, opts) do
    dfs(graph, V.get_vertex_index(graph, root), opts)
  end


  defp init_dfs(graph, root) do
    num_vertices = BitGraph.num_vertices(graph)
    %{
      root: root,
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
      Enum.reduce(neighbors, state, fn
        neighbor, state_acc ->
          if vertex_color(state, neighbor) != @white_vertex do
            state_acc
          else
            dfs_impl(graph, neighbor, vertex, apply_reduce(graph, neighbor, state_acc, reduce_fun), reduce_fun, reverse_dfs?)
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

  defp vertex_color(state, vertex) do
    Array.get(state[:color], vertex)
  end

  defp default_reduce_fun() do
    fn _graph, vertex, %{root: root, acc: acc} = _state ->
      [vertex | (acc || [root])]
    end
  end

  defp apply_reduce(_graph, _vertex, state, nil) do
    state
  end

  defp apply_reduce(graph, vertex, state, reduce_fun) when is_function(reduce_fun, 3) do
    acc = reduce_fun.(graph, vertex, state)
    Map.put(state, :acc, acc)
  end
end
