defmodule Growth.Calculate do
  alias Growth.Child
  alias Growth.LoadReference
  alias Growth.Measure
  alias Growth.Zscore

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

  @spec results(Measure.t(), Child.t()) :: Measure.t()
  def results(
        %Measure{weight: weight, height: height, head_circumference: head_circumference, bmi: bmi} =
          growth,
        %Child{gender: gender, age_in_months: age_in_months}
      ) do
    weight_result = calculate_result(age_in_months, weight, :weight, gender)

    height_result = calculate_result(age_in_months, height, :height, gender)

    bmi_result = calculate_result(age_in_months, bmi, :bmi, gender)

    head_circumference_result =
      calculate_result(age_in_months, head_circumference, :head_circumference, gender)

    result = %{
      weight_result: weight_result,
      height_result: height_result,
      head_circumference_result: head_circumference_result,
      bmi_result: bmi_result
    }

    %{growth | results: result}
  end

  @spec calculate_result(number(), number() | String.t(), atom(), atom()) :: number() | String.t()
  def calculate_result(age_in_months, measure, data_type, gender) when is_number(measure) do
    case LoadReference.load_data(data_type) do
      {:ok, data} ->
        data
        |> find_row(age_in_months, gender)
        |> add_zscore(measure)
        |> add_percentile()
        |> format_result()

      {:error, _cause} ->
        "no data found"
    end
  end

  def calculate_result(_age_in_months, _measure, _data_type, _gender) do
    "no results"
  end

  defp find_row(data, age_in_months, gender) do
    Enum.find(data, &(&1.age == age_in_months && &1.age_unit == "month" && &1.gender == gender))
  end

  defp add_zscore(%{l: l, m: m, s: s} = data, measure) do
    zscore = Zscore.calculate(measure, l, m, s)

    Map.put(data, :zscore, zscore)
  end

  defp add_percentile(%{zscore: zscore} = data) do
    percentile = Float.round(0.5 * (:math.erf(zscore / :math.sqrt(2)) + 1), 2)

    Map.put(data, :percentile, percentile)
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
