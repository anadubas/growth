defmodule GrowthWeb.Form.Measure do
  @moduledoc """
  Form schema to validate measure data information.

  Wrapped with `Zoi.Form.prepare/1` so empty HTML inputs (`""`) are treated as
  `nil` (nullable), matching how LiveView serialises untouched/cleared fields.

  `measure_date` is nullable per decision 1 of the multiple-measures plan
  (default strategy): the default-to-today is owned solely by
  `Growth.Measure.schema/0`; new rows are seeded with today's date via `new/1`.
  """

  @schema Zoi.Form.prepare(
            Zoi.map(
              %{
                measure_date: Zoi.date() |> Zoi.coerce() |> Zoi.nullish(),
                height: Zoi.number() |> Zoi.coerce() |> Zoi.min(0) |> Zoi.nullish(),
                weight: Zoi.number() |> Zoi.coerce() |> Zoi.min(0) |> Zoi.nullish(),
                head_circumference: Zoi.number() |> Zoi.coerce() |> Zoi.min(0) |> Zoi.nullish()
              },
              coerce: true
            )
          )

  @spec new() :: Phoenix.HTML.Form.t()
  @spec new(non_neg_integer()) :: Phoenix.HTML.Form.t()
  def new(index \\ 0) do
    today = Date.utc_today() |> Date.to_iso8601()
    form_name = row_name(index)
    form(%{measure_date: today}, form_name)
  end

  @spec form(map() | Zoi.Context.t()) :: Phoenix.HTML.Form.t()
  @spec form(map() | Zoi.Context.t(), atom() | String.t()) :: Phoenix.HTML.Form.t()
  @spec form(map() | Zoi.Context.t(), atom() | String.t(), keyword()) :: Phoenix.HTML.Form.t()
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
  def schema, do: @schema

  @doc """
  Returns the form name for the measure row at `index`, e.g. `measure[0]`,
  so each field renders as `measure[0][height]`.
  """
  @spec row_name(non_neg_integer()) :: String.t()
  def row_name(index), do: "measure[#{index}]"
end
