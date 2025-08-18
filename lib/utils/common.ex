defmodule BitGraph.Common do
  alias BitGraph.{V, E}

  alias Iter.Iterable

  def vertex_indices_to_ids(graph, indices) do
    Enum.map(indices, fn idx -> V.get_vertex(graph, idx) end)
  end

  def cycle?(graph, vertices) do
    circuit = [List.last(vertices) | vertices]
    Enum.all?(0..length(circuit) - 2, fn idx ->
      E.edge?(graph, Enum.at(circuit, idx), Enum.at(circuit, idx + 1))
    end)
  end

  def to_iterator(any) do
    Iter.IntoIterable.into_iterable(any)
  end

  def to_enum(any) do
    Iterable.to_list(any)
  end

end
