defmodule BitGraph.Algorithm.SCC.Utils do
  def wrap_component_handler({handler_fun, initial_value}) do
    wrap_component_handler(handler_fun, initial_value)
  end

  def wrap_component_handler(handler_fun, initial_value \\ nil) when is_function(handler_fun, 2) do
      fn component, acc ->
        handler_fun.(component, acc || initial_value)
      end
  end

end
