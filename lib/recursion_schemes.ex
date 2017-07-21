defmodule RecursionSchemes do
  @moduledoc """
  Documentation for RecursionSchemes.
  """

  alias RecursionSchemes.Combinators

  @doc """
  Hello world.

  ## Examples

      iex> RecursionSchemes.hello
      :world

  """
  def hello do
    :world
  end

  #def cata(base: base_case, rec: rec_case, join: join_fn) do
    #fn x ->
      #if Fix.base_case?(x) do
        #base_case.(x)
      #else
        #join_fn.(Fix.fix(x), cata(base: base_case, rec: rec_case, join: join_fn).(Fix.unfix(x)))
      #end
    #end
  #end

  #def cata(data, f) when is_function(f) do
    #if Fix.base_case?(data) do
      #f_base.(data)
    #else
      #Fix.mappend(f_rec.(Fix.unfix(data)), cata
    #end
  #end
end
