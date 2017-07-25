defmodule RecursionSchemes do
  @moduledoc """
  Documentation for RecursionSchemes.
  """
  alias RecStruct, as: RS

  @doc """
  cata (catamorphism), is a generalization of fold.
  When operating on lists, it is equivalent to List.foldr/3

  ## Examples

      iex> [3, 5, 2, 9]
      ...> |> RecursionSchemes.cata(
      ...>      0,
      ...>      fn (h, acc) -> h + acc end)
      19

      iex> 5
      ...> |> RecursionSchemes.cata(
      ...>      1,
      ...>      fn (n, acc) -> n * acc end)
      120
  """
  def cata(data, acc, f_rec) do
    if RS.base?(data) do
      acc
    else
      {elem, rest} = RS.unwrap(data)
      f_rec.(elem, cata(rest, acc, f_rec))
    end
  end

  @doc """
  cata/2 allows you to define a function in terms of a catamorphism.

  ## Examples

      iex> my_sum = RecursionSchemes.cata(
      ...>   0,
      ...>   fn (h, acc) -> h + acc end)
      ...> my_sum.([3, 5, 2, 9])
      19

      iex> factorial = RecursionSchemes.cata(
      ...>   1,
      ...>   fn (n, acc) -> n * acc end)
      ...> factorial.(5)
      120
  """
  def cata(acc, f_rec) when is_function(f_rec) do
    fn data ->
      cata(data, acc, f_rec)
    end
  end

  @doc """
  ana generalizes unfolding a recursive structure.

  Not guaranteed to terminate; unfolding ends when the finished?
  predicate returns true.

  ## Examples

      iex> RecursionSchemes.ana(
      ...>   {1, []}, # Initial state; starting value and accumulator
      ...>   fn x -> x > 5 end, # End unfolding after five iterations
      ...>   fn x -> {x * x, x + 1} end)
      [1, 4, 9, 16, 25]

      iex> RecursionSchemes.ana(
      ...>    {1, 0},
      ...>    fn x -> x == 16 end,
      ...>    fn x -> {x, x + 1} end)
      120
  """
  def ana({elem, acc}, finished?, unspool_f), do: ana(elem, finished?, unspool_f, acc)
  def ana(state, finished?, unspool_f, init_acc) do
    {elem, next_elem} = unspool_f.(state)
    if finished?.(next_elem) do
      RS.wrap(init_acc, elem)
    else
      RS.wrap(ana(next_elem, finished?, unspool_f, init_acc), elem)
    end
  end

  @doc """
  ana/2 returns an anonymous function so that you can define arity-1 functions
  in terms of ana.

  ## Examples

      iex> zip = RecursionSchemes.ana(
      ...>   fn {as, bs} -> as == [] || bs == [] end,
      ...>   fn {[a | as], [b | bs]} -> {{a, b}, {as, bs}} end)
      ...> zip.({{[1,2,3,4], ["a", "b", "c"]}, []})
      [{1, "a"}, {2, "b"}, {3, "c"}]
  """
  def ana(finished?, unspool_f) do
    fn state ->
      ana(state, finished?, unspool_f)
    end
  end

  @doc """
  hylo/5 generalizes unfolding a recursive structure and applying a catamorphism
  to the result.

  Not guaranteed to terminate; unfolding ends when the finished?
  predicate returns true.

  ## Examples

      iex> RecursionSchemes.hylo(
      ...>   {1, []}, # Initial state; starting value and accumulator
      ...>   fn x -> x > 5 end, # End unfolding after five iterations
      ...>   fn x -> {x * x, x + 1} end,
      ...>   0,
      ...>   fn (h, acc) -> h + acc end)
      55
  """
  def hylo({_v, _acc} = state, finished?, unspool_f, acc, f_rec) do
    state
    |> ana(finished?, unspool_f)
    |> cata(acc, f_rec)
  end

  @doc """
  hylo/2 generalizes unfolding a recursive structure and applying a catamorphism
  to the result.

  Not guaranteed to terminate; unfolding ends when the finished?
  predicate returns true.

  ## Examples

  iex> five_squares = RecursionSchemes.ana(
  ...>   fn x -> x > 5 end, # End unfolding after five iterations
  ...>   fn x -> {x * x, x + 1} end)
  ...> my_sum = RecursionSchemes.cata(
  ...>   0,
  ...>   fn (h, acc) -> h + acc end)
  ...> RecursionSchemes.hylo(five_squares, my_sum).({1, []})
  55
  """
  def hylo(anamorphism, catamorphism) when is_function(anamorphism) and is_function(catamorphism) do
    fn data ->
      catamorphism.(anamorphism.(data))
    end
  end
end
