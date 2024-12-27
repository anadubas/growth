defmodule Growth do
  @moduledoc """
  Growth keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Growth.Child
  alias Growth.Measure

  @doc """
  Create a child
  """
  @spec create_child(map()) :: {:ok, Child.t()}
  def create_child(attrs) do
    Child.new(attrs)
  end

  @doc """
  Create child measures results
  """
  @spec child_measure(map(), Child.t()) :: {:ok, Measure.t()}
  def child_measure(attrs, child) do
    Measure.new(attrs, child)
  end
end
