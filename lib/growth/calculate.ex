defmodule Growth.Calculate do

  alias Growth.LoadReference
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
    weight/ :math.pow(height / 100.0, 2)
  end

  @spec results(map()) :: map()
  def results(%{
        age_in_months: age_in_months,
        weight: weight,
        height: height,
        head_circumference: head_circumference,
        bmi: bmi,
        gender: gender
      } = growth) do
    weight_result =
      calculate_result(age_in_months, weight, :weight, gender)

    height_result =
      calculate_result(age_in_months, height, :height, gender)

    bmi_result =
      calculate_result(age_in_months, bmi, :bmi, gender)

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

  @spec calculate_result(number(), number(), atom(), atom()) :: {:ok, float} | {:error, String.t()}
  def calculate_result(age_in_months, measure, data_type, gender) do
    case LoadReference.load_data(data_type) do
      {:ok, data} ->
        data
        |> find_row(age_in_months, gender)
        |> add_zscore(measure)
        |> add_percentile
        |> format_result

      {:error, _cause} -> "no data found"
    end
  end

  defp find_row(data, age_in_months, gender) do
    data
    |> Enum.find(fn row ->
      row.age == age_in_months
      && row.age_unit == "month"
      && row.gender == gender
    end)
  end

  defp add_zscore(%{l: l, m: m, s: s} = data, measure) do
    zscore = Zscore.calculate(measure, l, m, s)

    data
    |> Map.put(:zscore, zscore)
  end

  defp add_percentile(%{zscore: zscore} = data) do
    percentile = Float.round(0.5 * (:math.erf(zscore / :math.sqrt(2)) + 1), 2)

    data
    |> Map.put(:percentile, percentile)
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
