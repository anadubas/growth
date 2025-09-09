defmodule Growth.Calculate do
  @moduledoc """
  Provides calculation functions for child growth assessment metrics.

  This module handles various calculations related to child growth monitoring, including:
    * Z-scores and percentiles for different anthropometric measurements:
        * Weight-for-age
        * Height-for-age
        * BMI-for-age
        * Head circumference-for-age
  """

  alias Growth.Child
  alias Growth.LoadReference
  alias Growth.Measure
  alias Growth.Zscore
  require :telemetry

  @days_in_month 30.4375

  @spec age_in_months(Date.t(), Date.t()) :: number()
  def age_in_months(birthday, measure_date) do
    measure_date
    |> Date.diff(birthday)
    |> Kernel./(@days_in_month)
    |> floor()
  end

  @spec bmi(number(), number()) :: number()
  def bmi(weight, height) do
    weight / :math.pow(height / 100.0, 2)
  end

  @doc """
  Calculates the growth assessment metrics (Z-scores and percentiles) for a child.

  ## Parameters
    - `growth`: A `Measure` struct containing the child's anthropometric data (weight, height, etc.).
    - `child`: A `Child` struct containing the child's gender and age in months.

  ## Returns
    - A `Measure` struct with added growth results (Z-scores, percentiles, and SD values).
  """
  @spec results(Measure.t(), Child.t()) :: Measure.t()
  def results(
        %Measure{weight: weight, height: height, head_circumference: head_circumference, bmi: bmi} =
          growth,
        %Child{} = child
      ) do
    :telemetry.span(
      [:growth, :calculation],
      %{child_age_in_months: child.age_in_months, child_gender: child.gender},
      fn ->
        weight_result = calculate_result(weight, :weight, child)
        height_result = calculate_result(height, :height, child)
        bmi_result = calculate_result(bmi, :bmi, child)

        head_circumference_result =
          calculate_result(head_circumference, :head_circumference, child)

        result = %{
          weight_result: weight_result,
          height_result: height_result,
          head_circumference_result: head_circumference_result,
          bmi_result: bmi_result
        }

        measure = %Measure{growth | results: result}

        {measure,
         %{
           has_weight_result: weight_result != "no results",
           has_height_result: height_result != "no results",
           has_bmi_result: bmi_result != "no results",
           has_head_circumference_result: head_circumference_result != "no results",
           success: true
         }}
      end
    )
  end

  @doc """
  Calculates the growth assessment metrics (Z-scores and percentiles) for a given measurement.

  ## Parameters
    - `age_in_months`: The child's age in months.
    - `measure`: The specific measurement (e.g., weight, height, etc.).
    - `data_type`: The type of measurement (e.g., `:weight`, `:height`).
    - `gender`: The child's gender.

  ## Returns
    - A map containing Z-scores, percentiles, and standard deviation values.
    - If no data is found, returns the string "no results".
  """
  @spec calculate_result(number(), atom(), Child.t()) :: map() | String.t()
  def calculate_result(measure, data_type, %Child{} = child)
      when is_number(measure) do
    :telemetry.span(
      [:growth, :calculation, data_type],
      %{
        data_type: data_type,
        child_gender: child.gender,
        age_in_months: child.age_in_months
      },
      fn ->
        case LoadReference.load_data(data_type, child) do
          {:ok, data} ->
            result =
              data
              |> add_zscore(measure)
              |> add_percentile()
              |> format_result()

            {result, %{success: true}}

          {:error, _} ->
            {"no data found", %{success: false}}
        end
      end
    )
  end

  def calculate_result(_age_in_months, _data_type, _child) do
    "no results"
  end

  defp add_zscore(%{l: l, m: m, s: s} = data, measure) do
    zscore = Zscore.calculate(measure, l, m, s)
    Map.put(data, :zscore, zscore)
  end

  defp add_percentile(%{zscore: zscore} = data) do
    percentile = Float.round(0.5 * (:math.erf(zscore / :math.sqrt(2)) + 1), 2)
    Map.put(data, :percentile, percentile * 100.0)
  end

  defp format_result(data) do
    %{
      sd0: data.sd0,
      sd1: data.sd1,
      sd2: data.sd2,
      sd3: data.sd3,
      sd1neg: data.sd1neg,
      sd2neg: data.sd2neg,
      sd3neg: data.sd3neg,
      zscore: data.zscore,
      percentile: data.percentile
    }
  end
end
