defmodule RecursionSchemes do
  @moduledoc """
  Documentation for RecursionSchemes.
  """

  @doc """
  cata is a catamorphism, a generalization of fold.

  ## Examples

      iex> RecursionSchemes.cata(
      ...>   [3, 5, 2, 9],
      ...>   fn ([]) -> 0 end,
      ...>   fn (h, acc) -> h + acc end)
      19

      iex> RecursionSchemes.cata(
      ...>   5,
      ...>   fn (0) -> 1 end,
      ...>   fn (n, acc) -> n * acc end)
      120
  """
  def cata(data, f_base, f_rec) do
    if Fix.base?(data) do
      f_base.(Fix.unwrap(data))
    else
      f_rec.(Fix.unwrap(data), cata(Fix.wrap(data), f_base, f_rec))
    end
  end

  @doc """
  cata/2 allows you to define a function in terms of a catamorphism.

  ## Examples

      iex> my_sum = RecursionSchemes.cata(
      ...>   fn ([]) -> 0 end,
      ...>   fn (h, acc) -> h + acc end)
      ...>   my_sum.([3, 5, 2, 9])
      19

      iex> factorial = RecursionSchemes.cata(
      ...>   fn (0) -> 1 end,
      ...>   fn (n, acc) -> n * acc end)
      ...> factorial.(5)
      120
  """
  def cata(f_base, f_rec) do
    fn data ->
      cata(data, f_base, f_rec)
    end
  end

  @doc """
  ana generalizes unfolding a recursive structure.

  Not guaranteed to terminate; unfolding ends when the finished_f
  predicate returns true.

  ## Examples

      iex> RecursionSchemes.ana(
      ...>   {1, []}, # Initial state; starting value and accumulator
      ...>   fn {x, _a} -> x > 5 end, # End unfolding after five iterations
      ...>   fn ({x, a}) -> {x + 1, a ++ [x * x]} end)
      [1, 4, 9, 16, 25]

      iex> RecursionSchemes.ana(
      ...>    {1, 0},
      ...>    fn {x, _a} -> x == 16 end,
      ...>    fn ({x, a}) -> {x + 1, x + a} end)
      120
  """
  def ana({_v, acc} = state, finished_f, unspool_f) do
    if finished_f.(state) do
      acc
    else
      new_state = unspool_f.(state)
      ana(new_state, finished_f, unspool_f)
    end
  end

  @doc """
  ana/2 returns an anonymous function so that you can define arity-1 functions
  in terms of ana.

  ## Examples

  iex> zip = RecursionSchemes.ana(
  ...>   fn {{as, bs}, acc} -> as == [] || bs == [] end,
  ...>   fn {{[a | as], [b | bs]}, acc} -> {{as, bs}, acc ++ [{a, b}]} end)
  ...> zip.({{[1,2,3,4], ["a", "b", "c"]}, []})
  [{1, "a"}, {2, "b"}, {3, "c"}]
  """
  def ana(finished_pred, unspool_f) do
    fn state ->
      ana(state, finished_pred, unspool_f)
    end
  end

  @doc """
  hylo generalizes unfolding a recursive structure and applying a catamorphism
  to the result.

  Not guaranteed to terminate; unfolding ends when the finished_f
  predicate returns true.

  ## Examples

      iex> RecursionSchemes.hylo(
      ...>   {1, []}, # Initial state; starting value and accumulator
      ...>   fn {x, _a} -> x > 5 end, # End unfolding after five iterations
      ...>   fn ({x, a}) -> {x + 1, a ++ [x * x]} end,
      ...>   fn ([]) -> 0 end,
      ...>   fn (h, acc) -> h + acc end)
      55
  """
  def hylo({_v, acc} = state, finished?, unspool_f, f_base, f_rec) do
    if finished?.(state) do
      cata(acc, f_base, f_rec)
    else
      new_state = unspool_f.(state)
      hylo(new_state, finished?, unspool_f, f_base, f_rec)
    end
  end

  @doc """
  hylo generalizes unfolding a recursive structure and applying a catamorphism
  to the result.

  Not guaranteed to terminate; unfolding ends when the finished_f
  predicate returns true.

  ## Examples

  iex> five_squares = RecursionSchemes.ana(
  ...>   fn {x, _a} -> x > 5 end, # End unfolding after five iterations
  ...>   fn ({x, a}) -> {x + 1, a ++ [x * x]} end)
  ...> my_sum = RecursionSchemes.cata(
  ...>   fn ([]) -> 0 end,
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
