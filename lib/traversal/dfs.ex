defmodule BitGraph.Dfs do
  alias BitGraph.V
  alias BitGraph.Neighbor, as: N
  alias BitGraph.Array

  @moduledoc """
  Depth-first search.
  Implementation roughly follows
  https://cp-algorithms.com/graph/depth-first-search.html
  """

  @white_vertex 0
  @gray_vertex 1
  @black_vertex 2

  @doc """
  Options:
  - `vertices` - list of vertex indices (not vertex ids!) or :all (default)
  - `state` - initial state
  - `direction` - direction of edges connected to current vertex
     - :forward - out-edges
     - :reverse - in-edges
     - :both - all edges
  - `process_vertex_fun` callback for processing vertices
  - `process_edge_fun` - callback for processing edges
  - `edge_process_order` - whether the (dfs tree) edge processing will be made
        - before (:preorder, default)
        - after (:postorder)
        - before and after (:both)
  """

  def run(graph, opts \\ []) do
    graph = update_graph_opts(graph, opts)
    vertices = build_vertices(graph, Keyword.get(opts, :vertices, :all))
    initial_state = Keyword.get(opts, :state) || (
      case vertices do
        [] -> nil
        list when is_struct(vertices, MapSet) or is_list(vertices) ->
          Enum.empty?(list) && nil || init_dfs(graph, opts)
        _other ->
          throw({:error, :invalid_vertex_list})
        end
    )

    Enum.reduce(vertices, initial_state, fn vertex, state_acc ->
      if vertex_color(state_acc, vertex) == @white_vertex do
        ## New component discovered
        dfs_impl(graph, vertex, Map.put(state_acc, :component_top, vertex))
      else
        state_acc
      end
    end)
  end

  defp update_graph_opts(graph, opts) do
    BitGraph.update_opts(graph, opts)
    |> then(fn g ->
      BitGraph.get_opts(g)[:neighbor_finder] && g
      || BitGraph.update_opts(g, neighbor_finder: N.default_neighbor_iterator())
    end)
  end

  defp build_vertices(graph, :all) do
    BitGraph.vertex_indices(graph)
  end

  defp build_vertices(_graph, vertex) when is_integer(vertex) do
    [vertex]
  end

  defp build_vertices(_graph, vertices) when is_list(vertices) or is_struct(vertices, MapSet) do
    vertices
  end

  defp init_dfs(graph, opts) do
    max_index = BitGraph.max_index(graph)

    %{
      component_top: nil, #root,
      direction: Keyword.get(opts, :direction, :forward),
      process_edge_fun:
        Keyword.get(opts, :process_edge_fun, default_process_edge_fun())
        |> normalize_process_edge_fun(),
      process_vertex_fun:
        Keyword.get(opts, :process_vertex_fun, default_process_vertex_fun())
        |> normalize_process_vertex_fun(),
      ## Order of processing for 'tree' edge:
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
      color: Array.new(max_index),
      ## Time of dfs entering the vertex
      time_in: Array.new(max_index),
      ## Time of dfs exiting vertex
      time_out: Array.new(max_index),
      parent: Array.new(max_index),
      acc: nil
    }
  end

  defp dfs_impl(graph, vertex, %{direction: direction} = state)
       when is_integer(vertex) do

    initial_state = init_vertex_processing(state, vertex)
    neighbor_iterator = vertex_neighbors(graph, vertex, direction)

    N.iterate(neighbor_iterator, initial_state,
      fn neighbor, acc ->
        process_edge(graph, acc, vertex, neighbor)
      end)
    |> finalize_vertex_processing(vertex)
  end

  defp init_vertex_processing(state, vertex) do
    time = inc_timer(state)
    Array.put(state[:time_in], vertex, time)
    Array.put(state[:color], vertex, @gray_vertex)
    process_vertex(state, vertex, :discovered)
  end

  defp finalize_vertex_processing(state, vertex) do
    state
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

  defp process_vertex(%{process_vertex_fun: process_vertex_fun} = state, vertex, event)
       when is_function(process_vertex_fun, 3) do
    Map.put(state, :acc, process_vertex_fun.(state, vertex, event))
  end

  defp process_edge(graph, %{edge_process_order: process_order} = state, vertex, neighbor) do
    case vertex_color(state, neighbor) do
      @black_vertex ->
        ## (vertex, neighbor) is either a cross edge or forward edge
        process_edge_impl(
          state,
          vertex,
          neighbor,
          (time_in(state, vertex) > time_in(state, neighbor) && :cross) || :forward
        )

      @gray_vertex ->
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
    fn state, prev_vertex, current_vertex, _edge_type ->
      process_edge_fun.(state, prev_vertex, current_vertex)
    end
  end

  defp normalize_process_edge_fun(process_edge_fun) when is_function(process_edge_fun, 4) do
    process_edge_fun
  end

  defp normalize_process_edge_fun(nil), do: nil

  defp process_edge_impl(
         %{process_edge_fun: process_edge_fun} = state,
         start_vertex,
         end_vertex,
         edge_type
       )
       when is_function(process_edge_fun, 4) do
    {next_action, acc} =
      case process_edge_fun.(state, start_vertex, end_vertex, edge_type) do
        {:next, acc} -> {:next, acc}
        {:stop, acc} -> {:stop, acc}
        acc -> {:next, acc}
      end

    {to_reduce_while_result(next_action), Map.put(state, :acc, acc)}
  end

  defp process_tree_edge(graph, state, start_vertex, end_vertex, :preorder) do
    process_edge_impl(state, start_vertex, end_vertex, :tree)
    |> then(fn
      {:halt, state} ->
        {:halt, state}

      {:cont, state} ->
        {:cont, dfs_impl(graph, end_vertex, state)}
    end)
  end

  defp process_tree_edge(graph, state, start_vertex, end_vertex, :both) do
    process_edge_impl(state, start_vertex, end_vertex, :tree)
    |> then(fn
      {:halt, state} ->
        {:halt, state}

      {:cont, state} ->
        dfs_impl(graph, end_vertex, state)
        |> process_edge_impl(start_vertex, end_vertex, :tree)
    end)
  end

  defp process_tree_edge(graph, state, start_vertex, end_vertex, :postorder) do
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
    V.out_neighbors(graph, vertex)
  end

  defp vertex_neighbors(graph, vertex, :reverse) do
    V.in_neighbors(graph, vertex)
  end

  defp vertex_neighbors(graph, vertex, :both) do
    V.neighbors(graph, vertex)
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
    ## Skip vertices with unassigned orders
    |> Array.reduce({[], 1}, fn 0, {list, idx} -> {list, idx + 1}
      el, {list, idx} -> {[{el, idx} | list], idx + 1}
    end)
    |> elem(0)
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
