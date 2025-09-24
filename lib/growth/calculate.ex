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
  alias Growth.Classify
  alias Growth.LoadReference
  alias Growth.Measure
  alias Growth.Percentile
  alias Growth.Zscore
  alias Growth.StructuredLogger
  require :telemetry

  @days_in_month 30.4375

  @spec age_in_months(Date.t(), Date.t()) :: number()
  def age_in_months(birthday, measure_date) do
    measure_date
    |> Date.diff(birthday)
    |> Kernel./(@days_in_month)
    |> floor()
  end

  @spec in_days(%{
          :calendar => atom(),
          :day => any(),
          :month => any(),
          :year => any(),
          optional(any()) => any()
        }) :: integer()
  def in_days(birthday, date \\ Date.utc_today()) do
    Date.diff(date, birthday)
  end

  @spec in_months_decimal(%{
          :calendar => atom(),
          :day => any(),
          :month => any(),
          :year => any(),
          optional(any()) => any()
        }) :: float()
  def in_months_decimal(birthday, date \\ Date.utc_today()) do
    days = in_days(birthday, date)
    Float.round(days / 30.4375, 2)
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
        %Measure{weight: weight, height: height, head_circumference: head_circumference, bmi: bmi} = growth,
        %Child{} = child
      ) do
    :telemetry.span(
      [:growth, :calculation],
      %{
        age_in_months: child.age_in_months,
        gender: child.gender,
        measure_date: child.measure_date
      },
      fn ->
        OpenTelemetry.Tracer.add_event("calculation.started", %{
          "input.has_weight" => not is_nil(growth.weight),
          "input.has_height" => not is_nil(growth.height),
          "input.has_bmi" => not is_nil(growth.bmi),
          "input.has_head_circumference" => not is_nil(growth.head_circumference)
        })

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

        OpenTelemetry.Tracer.add_event("calculation.completed", %{
          "results.calculated_measures" => count_successful_results(result),
          "results.has_errors" => has_calculation_errors?(result)
        })

        measure = %Measure{growth | results: result}

        {measure, %{count: 1},
         %{
           age_in_months: child.age_in_months,
           gender: child.gender,
           has_bmi_result: bmi_result != "no results",
           has_head_circumference_result: head_circumference_result != "no results",
           has_height_result: height_result != "no results",
           has_weight_result: weight_result != "no results",
           measure_date: child.measure_date,
           success: true
         }}
      end
    )
  end

  defp count_successful_results(result) do
    result
    |> Map.values()
    |> Enum.count(&(&1 != "no results"))
  end

  defp has_calculation_errors?(result) do
    result
    |> Map.values()
    |> Enum.any?(&(&1 == "no results"))
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
      [:growth, :calculation, :measure],
      %{
        age_in_months: child.age_in_months,
        gender: child.gender,
        measure_date: child.measure_date,
        data_type: data_type
      },
      fn ->
        StructuredLogger.info("Starting growth calculation", %{
          calculation_data_type: data_type,
          calculation_measure: measure,
          child_age_months: child.age_in_months,
          child_gender: child.gender
        })

        case LoadReference.load_data(data_type, child) do
          {:ok, data} ->
            StructuredLogger.debug("Reference data loaded successfully", %{
              reference_l: data.l,
              reference_m: data.m,
              reference_s: data.s,
              data_type: data_type
            })

            result =
              data
              |> add_zscore(measure)
              |> add_percentile()
              |> add_classification(data_type)
              |> format_result()

            StructuredLogger.info("Calculation completed", %{
              result_zscore: result.zscore,
              result_percentile: result.percentile,
              result_classification: result.classification,
              calculation_success: true
            })

            {result, success_metadata}

          {:error, reason} ->
            StructuredLogger.error("Reference data loading failed", %{
              error_reason: to_string(reason),
              calculation_data_type: data_type,
              calculation_success: false
            })

            {"no data found", error_metadata}
        end
      end
    )
  end

  def calculate_result(_measure, _data_type, _child), do: "no results"

  defp add_zscore(%{l: l, m: m, s: s} = data, measure) do
    zscore = Zscore.calculate(measure, l, m, s)
    Map.put(data, :zscore, zscore)
  end

  defp add_percentile(%{zscore: zscore} = data) do
    percentile = Percentile.calculate(zscore)
    Map.put(data, :percentile, percentile * 100.0)
  end

  defp add_classification(%{zscore: zscore} = data, data_type) do
    classification = Classify.calculate(data_type, zscore)
    Map.put(data, :classification, classification)
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
      percentile: data.percentile,
      classification: data.classification
    }
  end
end
