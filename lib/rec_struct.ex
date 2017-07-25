defprotocol RecStruct do
  @moduledoc """
  A recursive data structure.
  """

  @doc """
  unwrap/1 describes how to access the current and remaining pieces of
  data in a recursively defined structure.

  It should return a tuple of {current value, remaining values}
  """
  def unwrap(d)

  @doc """
  wrap/2 is a function for adding a new element to a recursive data structure.
  To have the dispatch on the protocol happen correctly, the data structure
  must be the first argument.
  """
  def wrap(ds, d)

  @doc """
  base?/1 is a predicate to test whether a recursively defined data structure
  is at its base case.
  """
  def base?(d)

  @doc """
  empty/1 is a function for obtaining the base value of a recursively
  defined data structure.
  """
  def empty(d)
end

defimpl RecStruct, for: List do
  def unwrap([]), do: {[], nil}
  def unwrap([h | t]), do: {h, t}

  def wrap(xs, x), do: [x | xs]

  def base?([]), do: true
  def base?(_), do: false

  def empty(_l), do: []
end

defimpl RecStruct, for: Integer do
  def unwrap(0), do: {0, nil}
  def unwrap(x), do: {x, x - 1}

  def wrap(xs, x), do: x + xs

  def base?(0), do: true
  def base?(_), do: false

  def empty(_n), do: 0
end

