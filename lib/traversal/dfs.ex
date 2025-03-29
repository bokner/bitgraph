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
        ## New component discovered
        dfs_impl(graph, vertex, Map.put(state_acc, :component_top, vertex))
      else
        state_acc
      end
    end)
  end

  defp init_dfs(graph, root, opts) do
    num_vertices = BitGraph.num_vertices(graph)
    %{
      component_top: root,
      direction: Keyword.get(opts, :direction, :forward),
      process_edge_fun: Keyword.get(opts, :process_edge_fun, default_process_edge_fun())
      |> normalize_process_edge_fun(),
      process_vertex_fun: Keyword.get(opts, :process_vertex_fun, default_process_vertex_fun())
      |> normalize_process_vertex_fun(),
      ## Processing order for 'tree' edge:
      ## :preorder - before DFS call
      ## :postorder - after DFS call
      ## :both - before and after DFS call
      edge_process_order: Keyword.get(opts, :edge_process_order, :preorder),
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

  defp dfs_impl(graph, vertex, %{direction: direction} = state)
    when is_integer(vertex) do
      time = inc_timer(state)
      Array.put(state[:time_in], vertex, time)
      Array.put(state[:color], vertex, @gray_vertex)
      initial_state = process_vertex(state, vertex, :discovered)
      Enum.reduce_while(vertex_neighbors(graph, vertex, direction), initial_state, fn
        neighbor, state_acc ->
          process_edge(graph, state_acc, vertex, neighbor)
      end)
      |> tap(fn _ ->
      Array.put(state[:time_out], vertex, inc_timer(state))
      Array.put(state[:color], vertex, @black_vertex)
      end)
      |> process_vertex(vertex, :processed)
  end

  defp inc_timer(%{timer: timer} = _state) do
    :ok = :counters.add(timer, 1, 1)
    :counters.get(timer, 1)
  end

  def vertex_color(state, vertex) do
    Array.get(state[:color], vertex)
  end

  defp default_process_vertex_fun() do
    fn %{acc: acc} = _state, _vertex, _edge_type ->
      acc
    end
  end

  defp default_process_edge_fun() do
    fn %{acc: acc} = _state, _vertex, _neighbor, _event? ->
      acc
    end
  end

  defp process_vertex(%{process_vertex_fun: process_vertex_fun} = state, vertex, event) when is_function(process_vertex_fun, 3) do
    Map.put(state, :acc, process_vertex_fun.(state, vertex, event))
  end

  defp process_edge(graph, %{edge_process_order: process_order} = state, vertex, neighbor) do
    case vertex_color(state, neighbor) do
      @black_vertex ->
        ## (vertex, neighbor) is either a cross edge or forward edge
        process_edge_impl(state, vertex, neighbor,
          time_in(state, vertex) > time_in(state, neighbor) && :cross || :forward)
      @gray_vertex  ->
        ## (vertex, neighbor) is a back edge
        process_edge_impl(Map.put(state, :dag, false), vertex, neighbor, :back)
      @white_vertex ->
        ## (vertex, neighbor) is a (dfs) tree edge)
        update_parent(state, neighbor, vertex)
        process_tree_edge(graph, state, vertex, neighbor, process_order)
    end

  end

  defp update_parent(%{parent: parent_ref} = _state, child, parent) do
    Array.put(parent_ref, child, parent)
  end


  ## Function for processing a vertex could be 2-arity (no options) or 3-arity
  defp normalize_process_vertex_fun(process_vertex_fun) when is_function(process_vertex_fun, 2) do
    fn state, vertex, _opts -> process_vertex_fun.(state, vertex) end
  end

  defp normalize_process_vertex_fun(process_vertex_fun) when is_function(process_vertex_fun, 3) do
    process_vertex_fun
  end

  defp normalize_process_vertex_fun(nil), do: nil

  ## Function for processing an edge could be 3-arity (ignoring edge type) or 4-arity

  defp normalize_process_edge_fun(process_edge_fun) when is_function(process_edge_fun, 3) do
    fn state, prev_vertex, current_vertex, _edge_type -> process_edge_fun.(state, prev_vertex, current_vertex) end
  end

  defp normalize_process_edge_fun(process_edge_fun) when is_function(process_edge_fun, 4) do
    process_edge_fun
  end

  defp normalize_process_edge_fun(nil), do: nil

  defp process_edge_impl(%{process_edge_fun: process_edge_fun} = state, start_vertex, end_vertex, edge_type) when is_function(process_edge_fun, 4) do
    {next_action, acc} = case process_edge_fun.(state, start_vertex, end_vertex, {:edge, edge_type}) do
      {:next, acc} -> {:next, acc}
      {:stop, acc} -> {:stop, acc}
      acc -> {:next, acc}
    end
    {to_reduce_while_result(next_action), Map.put(state, :acc, acc)}
  end

  defp process_tree_edge(graph, state, start_vertex, end_vertex, :preorder) do
    process_edge_impl(state, start_vertex, end_vertex, :tree)
    |> then(fn {:halt, state} ->
        {:halt, state}
      {:cont, state} ->
        {:cont, dfs_impl(graph, end_vertex, state)}
    end)
  end

  defp process_tree_edge(graph, state, start_vertex, end_vertex, :both) do
    process_edge_impl(state, start_vertex, end_vertex, :tree)
    |> then(fn {:halt, state} ->
      {:halt, state}
    {:cont, state} ->
      dfs_impl(graph, end_vertex, state)
      |> process_edge_impl(start_vertex, end_vertex, :tree)
    end)
  end

  defp process_tree_edge(graph,  state, start_vertex, end_vertex, :postorder) do
    dfs_impl(graph, end_vertex, state)
    |> process_edge_impl(start_vertex, end_vertex, :tree)
  end


  defp to_reduce_while_result(:next) do
    :cont
  end

  defp to_reduce_while_result(:stop) do
    :halt
  end

  defp to_reduce_while_result(_) do
    :cont
  end

  defp vertex_neighbors(graph, vertex, :forward) do
    E.out_neighbors(graph, vertex)
  end

  defp vertex_neighbors(graph, vertex, :reverse) do
    E.in_neighbors(graph, vertex)
  end

  defp vertex_neighbors(graph, vertex, :both) do
    MapSet.union(vertex_neighbors(graph, vertex, :forward),
    vertex_neighbors(graph, vertex, :reverse))
  end

  def acyclic?(state) do
    state.dag
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

  def parents(%{parent: parents_ref} = _dfs_state) do
    Array.to_list(parents_ref)
  end

  def parent(%{parent: parents_ref} = _dfs_state, vertex) do
    Array.get(parents_ref, vertex)
  end

  def time_ins(%{time_in: ref} = _dfs_state) do
    Array.to_list(ref)
  end

  def time_in(%{time_in: ref} = _dfs_state, vertex) do
    Array.get(ref, vertex)
  end

  def time_outs(%{time_out: ref} = _dfs_state) do
    Array.to_list(ref)
  end

  def time_out(%{time_out: ref} = _dfs_state, vertex) do
    Array.get(ref, vertex)
  end

end
