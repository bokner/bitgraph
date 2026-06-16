defmodule BitGraph.MST.Kruskal do
  alias InPlace.UnionFind

  def run(graph, opts \\ []) do
    opts = Keyword.merge(default_opts(), opts)
    dist_fun = Keyword.get(opts, :dist_fun)
    sorted_edges =
      graph
      |> BitGraph.edges()
      |> Enum.sort_by(fn %{from: from, to: to} = _edge ->
        dist_fun.(from, to)
      end, :asc)

    num_vertices = BitGraph.num_vertices(graph)
    uf = UnionFind.new(num_vertices)

    {_tree, _weight} = Enum.reduce_while(sorted_edges, {[], 0},
      fn %{from: from, to: to} = edge, {tree_acc, weight_acc} ->

    end)
  end

  defp default_opts() do
    [
      dist_fun: fn _v1, _v2 -> 1 end
    ]
  end

end
