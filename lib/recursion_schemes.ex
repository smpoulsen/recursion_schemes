defmodule RecursionSchemes do
  @moduledoc """
  Documentation for RecursionSchemes.
  """
  alias RecStruct, as: RS

  @doc """
  cata is a catamorphism, a generalization of fold.

  ## Examples

      iex> [3, 5, 2, 9]
      ...> |> RecursionSchemes.cata(
      ...>      fn ([]) -> 0 end,
      ...>      fn (h, acc) -> h + acc end)
      19

      iex> 5
      ...> |> RecursionSchemes.cata(
      ...>      fn (0) -> 1 end,
      ...>      fn (n, acc) -> n * acc end)
      120
  """
  def cata(data, f_base, f_rec) do
    {elem, rest} = RS.unwrap(data)
    if RS.base?(data) do
      f_base.(elem)
    else
      f_rec.(elem, cata(rest, f_base, f_rec))
    end
  end

  @doc """
  cata/2 allows you to define a function in terms of a catamorphism.

  ## Examples

      iex> my_sum = RecursionSchemes.cata(
      ...>   fn ([]) -> 0 end,
      ...>   fn (h, acc) -> h + acc end)
      ...> my_sum.([3, 5, 2, 9])
      19

      iex> factorial = RecursionSchemes.cata(
      ...>   fn (0) -> 1 end,
      ...>   fn (n, acc) -> n * acc end)
      ...> factorial.(5)
      120
  """
  def cata(f_base, f_rec) when is_function(f_base) and is_function(f_rec) do
    fn data ->
      cata(data, f_base, f_rec)
    end
  end

  @doc """
  cata/2 in which instead of passing two functions for the base case and the
  recursive case, a single function is passed in that must include function
  heads for both cases.

  ## Examples

      iex> [3,5,2,9]
      ...> |> RecursionSchemes.cata(
      ...>      fn ([], _acc) -> 0;
      ...>         (h, acc) -> h + acc end)
      19

      iex> 5
      ...> |> RecursionSchemes.cata(
      ...>      fn (0, _acc) -> 1;
      ...>         (n, acc) -> n * acc end)
      120
  """
  def cata(data, f) do
    {elem, rest} = RS.unwrap(data)
    if RS.base?(data) do
      f.(elem, elem)
    else
      f.(elem, cata(rest, f))
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
  hylo generalizes unfolding a recursive structure and applying a catamorphism
  to the result.

  Not guaranteed to terminate; unfolding ends when the finished?
  predicate returns true.

  ## Examples

      iex> RecursionSchemes.hylo(
      ...>   {1, []}, # Initial state; starting value and accumulator
      ...>   fn x -> x > 5 end, # End unfolding after five iterations
      ...>   fn x -> {x * x, x + 1} end,
      ...>   fn ([]) -> 0 end,
      ...>   fn (h, acc) -> h + acc end)
      55
  """
  def hylo({_v, _acc} = state, finished?, unspool_f, f_base, f_rec) do
    ana(state, finished?, unspool_f)
    |> cata(f_base, f_rec)
  end

  @doc """
  hylo generalizes unfolding a recursive structure and applying a catamorphism
  to the result.

  Not guaranteed to terminate; unfolding ends when the finished?
  predicate returns true.

  ## Examples

  iex> five_squares = RecursionSchemes.ana(
  ...>   fn x -> x > 5 end, # End unfolding after five iterations
  ...>   fn x -> {x * x, x + 1} end)
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
