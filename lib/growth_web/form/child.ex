defmodule GrowthWeb.Form.Child do
  @moduledoc """
  Form schema to validate child data information.
  """

  @schema Zoi.map(
            %{
              name: Zoi.string() |> Zoi.min(3) |> Zoi.max(512),
              gender: Zoi.enum(["male", "female"]),
              birthday: Zoi.date() |> Zoi.coerce()
            },
            coerce: true
          )

  @spec schema :: Zoi.schema()
  def schema, do: @schema
end
