defmodule GrowthWeb.Form.Measure do
  @moduledoc """
  Form schema to validate measure data information.
  """

  @schema Zoi.map(
            %{
              height: Zoi.number() |> Zoi.coerce() |> Zoi.min(0) |> Zoi.nullish(),
              weight: Zoi.number() |> Zoi.coerce() |> Zoi.min(0) |> Zoi.nullish(),
              head_circumference: Zoi.number() |> Zoi.coerce() |> Zoi.min(0) |> Zoi.nullish()
            },
            coerce: true
          )

  @spec schema :: Zoi.schema()
  def schema, do: @schema
end
