defmodule RecursionSchemes.Combinators do
  @moduledoc """
  Fixed-point combinators.
  """

  def u(f), do: f.(f)

  def fact() do
    u(
      fn (f) ->
        fn (x) ->
          if x == 0, do: 1, else: x * f.(f).(x - 1)
        end
      end
    )
  end

  @doc"""
  Y = λf.(λx.f (x x))(λx.f (x x))
  (define Y
  (lambda (f)
  ((lambda (x) (f (lambda (y) ((x x) y))))
  (lambda (x) (f (lambda (y) ((x x) y)))))))

  Combinators.y(fn f -> fn 0 -> 1; x -> x * f.(x - 1) end end).(5)
  """
  def y(f) do
    fix = fn (x) ->
      f.(fn (g) -> (x.(x)).(g) end)
    end
    fix.(fix)
  end

  #@doc """
  #"""
  #def fix(f, x) do
    #f.(fix(f)).(x)
  #end

  def fact_2(0), do: 1
  def fact_2(x), do: x * fact_2(x - 1)
end
