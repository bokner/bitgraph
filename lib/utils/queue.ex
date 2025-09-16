defmodule BitGraph.Queue do
  alias BitGraph.Array
  def new(max_capacity) when is_integer(max_capacity) and max_capacity > 0 do
    {max_capacity, Array.new(max_capacity + 2)}
  end

  def size({capacity, ref} = _queue) do
    Array.get(ref, size_address(capacity))
  end

  defp size_address(capacity) do
    capacity + 1
  end

  def empty?(queue) do
    size(queue) == 0
  end

  def front({_capacity, ref} = queue) do
    Array.get(ref, front_pointer(queue))
  end

  defp front_pointer({capacity, ref} = _queue) do
    Array.get(ref, front_address(capacity))
  end

  defp front_address(capacity) do
    capacity + 2
  end

  def rear({_capacity, ref} = queue) do
    pointer = rear_pointer(queue)
    Array.get(ref, pointer)
  end

  defp rear_pointer({capacity, ref} = queue) do
    rem(front_pointer(queue) + size(queue), capacity)
  end

  def enqueue({capacity, ref} = queue, element) do
    current_size = size(queue)
    if current_size == capacity, do: throw(:queue_over_capacity)
    Array.put(ref, rear_pointer(queue), element)
    Array.put(ref, size_address(queue), current_size + 1)
  end

  def dequeue({capacity, ref} = queue) do
      case size(queue) do
        0 -> nil
        current_size ->
          pointer = front_pointer(queue)
          Array.put(ref, size_address(queue), current_size - 1)
          Array.put(ref, front_address(capacity), rem(pointer + 1, capacity))
          Array.get(ref, pointer)
        end
  end
end
