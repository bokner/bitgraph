defmodule BitGraph.Algorithm.MST.Kruskal do
  alias InPlace.UnionFind
  alias BitGraph.V

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
      fn %{from: from, to: to} = _edge, {edges_acc, weight_acc}  = acc ->
        from_idx = V.get_vertex_index(graph, from)
        to_idx = V.get_vertex_index(graph, to)

        if UnionFind.find(uf, from_idx) == UnionFind.find(uf, to_idx) do
          {:cont, acc}
        else
          acc =  {
            [{from, to} | edges_acc],
            weight_acc + dist_fun.(from, to)
          }

          UnionFind.union(uf, from_idx, to_idx)
          if UnionFind.set_size(uf, 1) == num_vertices do
            {:halt, acc}
          else
            {:cont, acc}
          end
        end
    end)
  end

  defp default_opts() do
    [
      dist_fun: fn _v1, _v2 -> 1 end
    ]
  end

end
