defmodule GrowthWeb.Form.Measure do
  @moduledoc """
  Form schema to validate measure data information.
  """

  @schema Zoi.map(
            %{
              measure_date: Zoi.date() |> Zoi.coerce() |> Zoi.nullish(),
              height: Zoi.number() |> Zoi.coerce() |> Zoi.min(0) |> Zoi.nullish(),
              weight: Zoi.number() |> Zoi.coerce() |> Zoi.min(0) |> Zoi.nullish(),
              head_circumference: Zoi.number() |> Zoi.coerce() |> Zoi.min(0) |> Zoi.nullish()
            },
            coerce: true
          )

  @spec schema :: Zoi.schema()
  def schema do
    Zoi.transform(@schema, fn
      %{measure_date: nil} = data ->
        today = Date.utc_today()
        Map.update(data, :measure_date, today, fn _ -> today end)

      data ->
        data
    end)
  end
end
