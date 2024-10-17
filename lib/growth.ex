defmodule Growth do
  @moduledoc """
  Growth keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Growth.Child
  alias Growth.Measure

  @doc"""
  Create a child
  """
  @spec create_child(map()) :: {:ok, %Child{}} | {:error, term()}
  def create_child(attrs) do
    attrs
    |> Child.new()
  end

  @doc"""
  Create child measures results
  """
  @spec child_measure(map(), %Child{}) :: {:ok, %Measure{}} | {:error, term()}
  def child_measure(attrs, child) do
    attrs
    |> Measure.new(child)
  end
end
