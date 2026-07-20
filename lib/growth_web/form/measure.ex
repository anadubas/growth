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

  @spec form(map() | Zoi.Context.t()) :: Phoenix.HTML.Form.t()
  @spec form(map() | Zoi.Context.t(), atom()) :: Phoenix.HTML.Form.t()
  @spec form(map() | Zoi.Context.t(), atom(), keyword()) :: Phoenix.HTML.Form.t()
  def form(attrs, form_name \\ :measure, opts \\ [])

  def form(%Zoi.Context{} = attrs, form_name, opts) do
    Phoenix.Component.to_form(attrs, Keyword.put(opts, :as, form_name))
  end

  def form(attrs, form_name, opts) do
    attrs
    |> parse()
    |> form(form_name, opts)
  end

  @spec parse(map()) :: Zoi.Context.t()
  def parse(attrs) do
    Zoi.Form.parse(schema(), attrs)
  end

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
