defprotocol Fix do
  def wrap(d)
  def unwrap(d)
  def base?(d)
end

defimpl Fix, for: List do
  def wrap([]), do: []
  def wrap([_h | t]), do: t

  def unwrap([]), do: []
  def unwrap([h | _t]), do: h

  def base?([]), do: true
  def base?(_), do: false
end

defimpl Fix, for: Integer do
  def wrap(0), do: 0
  def wrap(x), do: x - 1

  def unwrap(0), do: 0
  def unwrap(x), do: x

  def base?(0), do: true
  def base?(_), do: false
end

