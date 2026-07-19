defmodule Growth.Measure do
  @moduledoc """
  Represents anthropometric measurement data for a child and calculates derived growth metrics.

  The `Growth.Measure` struct stores raw measurement inputs (weight, height, head circumference),
  calculates BMI, and generates growth assessment results (Z-scores and percentiles) based on
  WHO growth standards.

  This module provides functionality to:

  * Create a new measurement record
  * Automatically calculate age in months and decimal
  * Automatically compute BMI (if possible)
  * Generate Z-scores and percentiles via `Growth.Calculate`

  ## Fields

  * `:child` - A `Growth.Child` struct representing the child measured.
  * `:measure_date` - The date when the anthropometric measurement was taken (defaults to today).
  * `:age_in_months` - Calculated age in months based on birthday and measurement date.
  * `:age_in_decimal` - Calculate age in months, with decimal precision, based on birthday and measure date.
  * `:weight` - Weight in kilograms.
  * `:height` - Height in centimeters.
  * `:head_circumference` - Head circumference in centimeters.
  * `:bmi` - Computed BMI (or `nil` if not enough data).
  * `:results` - A map containing WHO growth results (Z-scores, percentiles, SD lines).

  ## Example

      iex> child = %Growth.Child{name: "Ana", gender: "female", birthday: ~D[2021-01-01]}
      iex> {:ok, measure} = Growth.Measure.new(%{measure_date: ~D[2024-01-01], weight: 14.0, height: 95.0}, child)
      iex> measure.age_in_months
      35
      iex> measure.age_in_decimal
      35.98
      iex> measure.bmi
      15.51246537396122
      iex> measure.results.weight.zscore
      0.1894881415953376
  """

  alias Growth.Calculate
  alias Growth.Child

  @schema Zoi.struct(
            __MODULE__,
            %{
              measure_date: Zoi.date() |> Zoi.nullish(),
              age_in_months: Zoi.integer() |> Zoi.min(0) |> Zoi.nullish(),
              age_in_decimal: Zoi.number() |> Zoi.min(0.0) |> Zoi.nullish(),
              height: Zoi.number() |> Zoi.min(0) |> Zoi.nullish(),
              weight: Zoi.number() |> Zoi.min(0) |> Zoi.nullish(),
              head_circumference: Zoi.number() |> Zoi.min(0) |> Zoi.nullish(),
              bmi: Zoi.number() |> Zoi.min(0) |> Zoi.nullish(),
              child: Zoi.struct(Child) |> Zoi.required(),
              results: Zoi.map() |> Zoi.default(%{}) |> Zoi.optional()
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Create a measure result for a child
  """
  @spec new(map(), Child.t()) :: {:ok, t()} | {:error, [Zoi.Error.t()]}
  def new(%{} = attrs, %Child{} = child) do
    with {:ok, measure} <- Zoi.parse(schema(), Map.put(attrs, :child, child)),
         {:ok, measure} <- add_results(measure) do
      :telemetry.execute([:growth, :measure, :submitted], %{count: 1}, %{
        age_in_months: measure.age_in_months,
        gender: child.gender,
        measure_date: measure.measure_date,
        has_weight: not is_nil(measure.weight),
        has_height: not is_nil(measure.height),
        has_head_circumference: not is_nil(measure.head_circumference)
      })

      {:ok, measure}
    end
  end

  defp add_results(%__MODULE__{} = growth) do
    {:ok, Calculate.results(growth)}
  end

  @spec schema :: Zoi.schema()
  def schema do
    Zoi.transform(@schema, fn %__MODULE__{child: child} = measure ->
      bmi =
        if not is_nil(measure.weight) and not is_nil(measure.height) do
          Calculate.bmi(measure.weight, measure.height)
        else
          nil
        end

      measure_date = (is_nil(measure.measure_date) && Date.utc_today()) || measure.measure_date
      age_in_months = Calculate.age_in_months(child.birthday, measure_date)
      age_in_decimal = Calculate.in_months_decimal(child.birthday, measure_date)

      {:ok,
       %{
         measure
         | measure_date: measure_date,
           age_in_months: age_in_months,
           age_in_decimal: age_in_decimal,
           bmi: bmi
       }}
    end)
  end
end
