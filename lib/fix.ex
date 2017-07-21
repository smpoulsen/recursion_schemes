defprotocol Fix do
  def cata(f_empty, f_data, data)
end

defimpl Fix, for: List do
  def cata([], f_empty, _f_data), do: f_empty.([])
  def cata([h | t], f_empty, f_data), do: f_data.(h, cata(t, f_empty, f_data))
end

