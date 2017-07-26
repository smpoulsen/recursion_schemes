defmodule RecursionSchemes do
  @moduledoc """
  Generic recursion schemes for working with recursively defined data structures.

  Recursion schemes provide functionality for consuming and creating recursive structures;
  they factor out the explicit recursion.

  The requirement for using these functions with user defined recursive data structures
  is an implementation of the RecStruct protocol.

  See [Functional Programming with Bananas Lenses Envelopes and Barbed Wire](http://axiom-wiki.newsynthesis.org/public/refs/Meijer-db-utwente-40501F46.pdf)
  for the seminal paper describing recursion schemes.
  """
  alias RecStruct, as: RS

  @doc """
  `cata/3` (catamorphism) is a function for consuming a recursive data structure.

  It is a generalization of fold; when operating on lists, it is equivalent to List.foldr/3

  Given three arguments, a data structure, an accumulator, and a function, it applies
  the function to the elements of the data structure and rolls them into the accumulator.

  `cata :: f a -> b -> (a -> b -> b) -> b`

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
  @spec cata(any(), any(), ((any(), any()) -> any())) :: any()
  def cata(data, acc, f) do
    if RS.base?(data) do
      acc
    else
      {elem, rest} = RS.unwrap(data)
      f.(elem, cata(rest, acc, f))
    end
  end

  @doc """
  `cata/2` returns a closure over `cata/3` with the accumulator and function applied.

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
  @spec cata(any(), ((any(), any()) -> any())) :: (any() -> any())
  def cata(acc, f) when is_function(f) do
    fn data ->
      cata(data, acc, f)
    end
  end

  @doc """
  `ana/3` (anamorphism) generalizes unfolding a recursive structure.

  Given a {seed value, accumulator} tuple, a predicate to end the unfolding,
  and a function that takes a seed value and returns a tuple of
  {value to accumulate, next seed}, returns an unfolded structure.

  Not guaranteed to terminate; unfolding ends when the `finished?`
  predicate returns true. If `finished?` never evaluates to true,
  the unfolding will never end.

  `ana :: {a, f a} -> (a -> bool) -> (a -> {a, a}) -> f a`

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
  @spec ana({any(), any()}, (any() -> boolean()), (any() -> {any(), any()})) :: any()
  def ana({seed, acc} = _init_state, finished?, unspool_f), do: ana_helper(seed, finished?, unspool_f, acc)
  defp ana_helper(state, finished?, unspool_f, init_acc) do
    {elem, next_elem} = unspool_f.(state)
    if finished?.(next_elem) do
      RS.wrap(init_acc, elem)
    else
      RS.wrap(ana_helper(next_elem, finished?, unspool_f, init_acc), elem)
    end
  end

  @doc """
  `ana/2` returns a closure over `ana/3` so that you can define arity-1 functions
  in terms of ana.

  ## Examples

      iex> zip = RecursionSchemes.ana(
      ...>   fn {as, bs} -> as == [] || bs == [] end,
      ...>   fn {[a | as], [b | bs]} -> {{a, b}, {as, bs}} end)
      ...> zip.({{[1,2,3,4], ["a", "b", "c"]}, []})
      [{1, "a"}, {2, "b"}, {3, "c"}]
  """
  @spec ana((any() -> boolean()), (any() -> {any(), any()})) :: ({any(), any()} -> any())
  def ana(finished?, unspool_f) do
    fn state ->
      ana(state, finished?, unspool_f)
    end
  end

  @doc """
  `hylo/5` (hylomorphism) generalizes unfolding a recursive structure and folding
  the result.

  Not guaranteed to terminate; unfolding ends when the `finished?`
  predicate returns true. If `finished?` never evaluates to true,
  the unfolding will never end.

  ## Examples

      iex> RecursionSchemes.hylo(
      ...>   {1, []}, # Initial state; starting value and accumulator
      ...>   fn x -> x > 5 end, # End unfolding after five iterations
      ...>   fn x -> {x * x, x + 1} end,
      ...>   0,
      ...>   fn (h, acc) -> h + acc end)
      55
  """
  @spec hylo({any(), any()}, (any() -> boolean()), (any() -> {any(), any()}), any(), (any(), any() -> any())) :: any()
  def hylo({_v, _acc} = init_state, finished?, unspool_f, acc, fold_f) do
    init_state
    |> ana(finished?, unspool_f)
    |> cata(acc, fold_f)
  end

  @doc """
  `hylo/2` generalizes unfolding a recursive structure and applying a catamorphism
  to the result.

  It takes an already defined catamorphism and anamorphism as its arguments.

  Not guaranteed to terminate; unfolding ends when the `finished?`
  predicate returns true. If `finished?` never evaluates to true,
  the unfolding will never end.

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
  @spec hylo((any() -> any()), (any() -> any())) :: any()
  def hylo(anamorphism, catamorphism) when is_function(anamorphism) and is_function(catamorphism) do
    fn data ->
      catamorphism.(anamorphism.(data))
    end
  end

  @doc """
  `para/3` or paramorphisim is similar to catamorphism; the major difference
  is that the recursion function receives the current piece of data, the remaining
  data, and the accumulator as its arguments (contrast with the current piece of
  data and the accumulator in catamorphism).

  ## Examples

      iex> RecursionSchemes.para(
      ...>   [1, 2, 3, 4, 5],
      ...>   [],
      ...>   fn (_x, xs, acc) -> [xs | acc] end)
      [[2, 3, 4, 5], [3, 4, 5], [4, 5], [5], []]
  """
  @spec para(any(), any(), ((any(), any(), any()) -> any())) :: any()
  def para(data, acc, f) do
    if RS.base?(data) do
      acc
    else
      {elem, rest} = RS.unwrap(data)
      f.(elem, rest, para(rest, acc, f))
    end
  end

  @doc """
  `para/2` is a closure over `para/3` with the accumulator and function applied.

  ## Examples

  iex> suffixes = RecursionSchemes.para(
  ...>   [],
  ...>   fn (_x, xs, acc) -> [xs | acc] end)
  ...> suffixes.([1, 2, 3, 4, 5])
  [[2, 3, 4, 5], [3, 4, 5], [4, 5], [5], []]
  """
  @spec para(any(), ((any(), any(), any()) -> any())) :: (any() -> any())
  def para(acc, f) do
    fn data ->
      para(data, acc, f)
    end
  end

  @doc """
  `apo/2` (apomorphism) is an unfolding function similar to `ana/3` and dual to `para/3`.
  It takes a `{seed, accumulator}` tuple and an unspooling function.

  Instead of supplying a `finished?` predicate, the unspooling function must return two
  possible cases - an `{:ok, value}` tuple and a `{:halt, value}` tuple. When the return
  value is the `:halt` tuple, the unfolding will end.

  If a `{:halt, _}` tuple is never returned, the function will not terminate.

  ## Examples

      iex> RecursionSchemes.apo(
      ...>   {1, []}, # Initial state; starting value and accumulator
      ...>   fn 5 = x -> {{:halt, x * x}, nil};
      ...>          x -> {{:ok, x * x}, x + 1} end)
      [1, 4, 9, 16, 25]

      iex> RecursionSchemes.apo(
      ...>    {1, 0},
      ...>    fn 15 = x -> {{:halt, x}, x + 1};
      ...>            x -> {{:ok, x}, x + 1} end)
      120
  """
  @spec apo({any(), any()}, (any() -> any())) :: any()
  def apo({seed, acc} = _init_state, unspool_f), do: apo_helper(seed, unspool_f, acc)
  defp apo_helper(state, unspool_f, init_acc) do
    {elem, next_elem} = unspool_f.(state)
    case elem do
      {:halt, val} ->
        RS.wrap(init_acc, val)
      {:ok, val} ->
        RS.wrap(apo_helper(next_elem, unspool_f, init_acc), val)
      {_, _} ->
        {:error, {:recursion_schemes, :bad_return_value}}
    end
  end

  @doc """
  `apo/1` is a closure over `apo/2` that applies the unspooling function.

  ## Examples

      iex> zip = RecursionSchemes.apo(
      ...>   fn {[a | as], [b | bs]} ->
      ...>     if as == [] or bs == [] do
      ...>       {{:halt, {a, b}}, nil}
      ...>     else
      ...>       {{:ok, {a, b}}, {as, bs}}
      ...>     end
      ...>   end)
      ...> zip.({{[1,2,3,4], ["a", "b", "c"]}, []})
      [{1, "a"}, {2, "b"}, {3, "c"}]
  """
  @spec apo((any() -> any())) :: (any() -> any())
  def apo(unspool_f) when is_function(unspool_f) do
    fn data ->
      apo(data, unspool_f)
    end
  end
end
