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

  @type t :: %__MODULE__{
          height: number() | nil,
          weight: number() | nil,
          head_circumference: number() | nil,
          bmi: number() | String.t() | nil,
          child: Child.t() | nil,
          results: map()
        }

  defstruct [
    :weight,
    :height,
    :head_circumference,
    :bmi,
    :child,
    results: %{}
  ]

  @doc """
  Create a measure result for a child
  """
  @spec new(map(), Child.t()) :: {:ok, t()}
  def new(attrs, child) do
    attrs
    |> create_struct(child)
    |> add_bmi()
    |> add_results(child)
  end

  defp create_struct(attrs, child) do
    %__MODULE__{
      height: attrs.height,
      weight: attrs.weight,
      head_circumference: attrs.head_circumference,
      child: child
    }
  end

  defp add_bmi(%__MODULE__{weight: weight, height: height} = growth)
       when is_number(weight) and is_number(height) do
    %{growth | bmi: Calculate.bmi(weight, height)}
  end

  defp add_bmi(%__MODULE__{} = growth) do
    %{growth | bmi: "no measure"}
  end

  defp add_results(%__MODULE__{bmi: "no measure"} = growth, _child) do
    {:ok, %{growth | results: %{}}}
  end

  defp add_results(%__MODULE__{} = growth, %Child{} = child) do
    {:ok, Calculate.results(growth, child)}
  end
end
