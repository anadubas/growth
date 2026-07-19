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
  alias Growth.Result
  alias Growth.Zscore

  @days_in_month 30.4375

  @spec age_in_months(Date.t(), Date.t()) :: number()
  def age_in_months(birthday, measure_date) do
    measure_date
    |> Date.diff(birthday)
    |> Kernel./(@days_in_month)
    |> floor()
  end

  @spec in_days(Date.t()) :: integer()
  @spec in_days(Date.t(), Date.t()) :: integer()
  def in_days(birthday, date \\ Date.utc_today()) do
    Date.diff(date, birthday)
  end

  @spec in_months_decimal(Date.t()) :: float()
  @spec in_months_decimal(Date.t(), Date.t()) :: float()
  def in_months_decimal(birthday, date \\ Date.utc_today()) do
    birthday
    |> in_days(date)
    |> Kernel./(@days_in_month)
    |> Float.round(2)
  end

  @spec bmi(number(), number()) :: number()
  def bmi(weight, height) do
    weight / :math.pow(height / 100.0, 2)
  end

  @doc """
  Calculates the growth assessment metrics (Z-scores and percentiles) for a child.

  ## Parameters

  * `measure`: A `Measure` struct containing the child's anthropometric data (weight, height, etc.) and child's details.

  ## Returns

  * A `Measure` struct with added growth results (Z-scores, percentiles, and SD values).
  """
  @spec results(Measure.t()) :: Measure.t()
  def results(%Measure{child: %Child{} = child} = measure) do
    :telemetry.span(
      [:growth, :calculation],
      %{
        age_in_months: measure.age_in_months,
        gender: child.gender,
        measure_date: measure.measure_date
      },
      fn ->
        weight_result = calculate_result(:weight, measure)
        height_result = calculate_result(:height, measure)
        bmi_result = calculate_result(:bmi, measure)
        head_circumference_result = calculate_result(:head_circumference, measure)

        results = %{
          weight: weight_result,
          height: height_result,
          head_circumference: head_circumference_result,
          bmi: bmi_result
        }

        measure = %Measure{measure | results: results}

        {measure, %{count: 1},
         %{
           age_in_months: measure.age_in_months,
           gender: child.gender,
           has_bmi_result: bmi_result.available?,
           has_head_circumference_result: head_circumference_result.available?,
           has_height_result: height_result.available?,
           has_weight_result: weight_result.available?,
           measure_date: measure.measure_date,
           success: true
         }}
      end
    )
  end

  @doc """
  Calculates the growth assessment metrics (Z-scores and percentiles) for a given measurement.

  ## Parameters

  * `data_type`: The type of measurement (e.g., `:weight`, `:height`).
  * `measure`: The child's anthropometric data and details.

  ## Returns

  * A result struct
  """
  @spec calculate_result(atom(), Measure.t()) :: Result.t()
  def calculate_result(data_type, %Measure{child: %Child{} = child} = measure) do
    :telemetry.span(
      [:growth, :calculation, :measure],
      %{
        age_in_months: measure.age_in_months,
        gender: child.gender,
        measure_date: measure.measure_date,
        data_type: data_type
      },
      fn ->
        with value when is_number(value) <- Map.get(measure, data_type),
             {:ok, data} <- LoadReference.load_data(data_type, measure) do
          result =
            data
            |> add_zscore(value)
            |> add_percentile()
            |> add_classification(data_type)
            |> format_result()
            |> then(&Result.new(true, &1))

          meta_for_calculate(measure, result, data_type, true)
        else
          # NOTE: (jpd) fires when reference data is missing for this age/gender/type
          {:error, _} ->
            meta_for_calculate(measure, Result.new(false, %{}), data_type, false)

          # NOTE: (jpd) fires when measurement is not numeric
          _ ->
            meta_for_calculate(measure, Result.new(false, %{}), data_type, false)
        end
      end
    )
  end

  defp add_zscore(%{l: l, m: m, s: s} = data, value) do
    zscore = Zscore.calculate(value, l, m, s)
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

  defp meta_for_calculate(%Measure{} = measure, %Result{} = result, data_type, success) do
    {result,
     %{
       age_in_months: measure.age_in_months,
       data_type: data_type,
       gender: measure.child.gender,
       measure_date: measure.measure_date,
       success: success
     }}
  end
end
