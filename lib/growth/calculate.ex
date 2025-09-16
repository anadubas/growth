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
        %Measure{weight: weight, height: height, head_circumference: head_circumference, bmi: bmi} =
          growth,
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

    %Measure{
      growth
      | results: %{
          weight: calculate_result(weight, :weight, child),
          height: calculate_result(height, :height, child),
          head_circumference: calculate_result(head_circumference, :head_circumference, child),
          bmi: calculate_result(bmi, :bmi, child)
        }
    }
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
        case LoadReference.load_data(data_type, child) do
          {:ok, %{l: l, m: m, s: s} = data} ->
            result =
              data
              |> add_zscore(measure)
              |> add_percentile()
              |> add_classification(data_type)
              |> format_result()

            {result,
             %{
               age_in_months: child.age_in_months,
               data_type: data_type,
               gender: child.gender,
               measure_date: child.measure_date,
               success: true
             }}

          {:error, _} ->
            {"no data found",
             %{
               age_in_months: child.age_in_months,
               data_type: data_type,
               gender: child.gender,
               measure_date: child.measure_date,
               success: false
             }}
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
    percentile = Float.round(0.5 * (:math.erf(zscore / :math.sqrt(2)) + 1), 2)
    Map.put(data, :percentile, percentile * 100.0)
  end

  defp add_classification(%{zscore: z} = data, :weight) do
    classification =
      cond do
        z < -3 -> "Baixo peso grave"
        z < -2 -> "Baixo peso"
        z <= 2 -> "Eutrófico"
        z <= 3 -> "Sobrepeso"
        true -> "Obesidade"
      end

    Map.put(data, :classification, classification)
  end

  defp add_classification(%{zscore: z} = data, :height) do
    classification =
      cond do
        z < -3 -> "Muito baixa estatura"
        z < -2 -> "Baixa estatura"
        true -> "Estatura adequada"
      end

    Map.put(data, :classification, classification)
  end

  defp add_classification(%{zscore: z} = data, :bmi) do
    classification =
      cond do
        z < -3 -> "Magreza acentuada"
        z < -2 -> "Magreza"
        z <= 1 -> "Eutrofia"
        z <= 2 -> "Sobrepeso"
        z <= 3 -> "Obesidade"
        true -> "Obesidade grave"
      end

    Map.put(data, :classification, classification)
  end

  defp add_classification(%{zscore: z} = data, :head_circumference) do
    classification =
      cond do
        z < -2 -> "Microcefalia"
        z > 2 -> "Macrocefalia"
        true -> "Normal"
      end

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
