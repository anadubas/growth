defmodule Growth.Measure do
  @moduledoc """
  Represents anthropometric measurement data for a child and calculates derived growth metrics.

  The `Growth.Measure` struct stores raw measurement inputs (weight, height, head circumference),
  calculates BMI, and generates growth assessment results (Z-scores and percentiles) based on
  WHO growth standards.

  This module provides functionality to:
    * Create a new measurement record
    * Automatically compute BMI (if possible)
    * Generate Z-scores and percentiles via `Growth.Calculate`

  ## Fields

    * `:weight` - Weight in kilograms.
    * `:height` - Height in centimeters.
    * `:head_circumference` - Head circumference in centimeters.
    * `:bmi` - Computed BMI (or `"no measure"` if not enough data).
    * `:child` - A `Growth.Child` struct representing the child measured.
    * `:results` - A map containing WHO growth results (Z-scores, percentiles, SD lines).

  ## Example

      iex> child = %Growth.Child{name: "Ana", gender: "female", birthday: ~D[2021-01-01], age_in_months: 36}
      iex> {:ok, measure} = Growth.Measure.new(%{weight: 14.0, height: 95.0}, child)
      iex> measure.bmi
      15.5
      iex> measure.results[:weight_result][:zscore]
      -0.2  # Example value
  """

  alias Growth.Calculate
  alias Growth.Child

  @schema Zoi.struct(
            __MODULE__,
            %{
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
         {:ok, measure} <- add_results(measure, child) do
      :telemetry.execute([:growth, :measure, :submitted], %{count: 1}, %{
        age_in_months: child.age_in_months,
        gender: child.gender,
        measure_date: child.measure_date,
        has_weight: not is_nil(measure.weight),
        has_height: not is_nil(measure.height),
        has_head_circumference: not is_nil(measure.head_circumference)
      })

      {:ok, measure}
    end
  end

  defp add_results(%__MODULE__{bmi: nil} = growth, _child) do
    {:ok, %__MODULE__{growth | results: %{}}}
  end

  defp add_results(%__MODULE__{} = growth, %Child{} = child) do
    {:ok, Calculate.results(growth, child)}
  end

  @spec schema :: Zoi.schema()
  def schema do
    Zoi.transform(@schema, fn
      %__MODULE__{height: height, weight: weight} = child
      when not is_nil(height) and not is_nil(weight) ->
        {:ok, %{child | bmi: Calculate.bmi(weight, height)}}

      %__MODULE__{} = child ->
        {:ok, %{child | bmi: nil}}
    end)
  end
end
