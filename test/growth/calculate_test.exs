defmodule Growth.CalculateTest do
  use ExUnit.Case, async: true

  alias Growth.{Calculate, Child, Measure}

  describe "age_in_months/2" do
    test "returns correct age in months" do
      birthday = ~D[2020-01-01]
      measure_date = ~D[2020-03-01]

      months = Calculate.age_in_months(birthday, measure_date)
      assert months == 1
    end
  end

  describe "bmi/2" do
    test "calculates BMI correctly" do
      bmi = Calculate.bmi(20, 100)
      assert Float.round(bmi, 1) == 20.0
    end
  end

  test "returns a Measure struct with results" do
    :meck.new(Growth.Zscore, [:passthrough])
    :meck.expect(Growth.Zscore, :calculate, fn _, _, _, _ -> 0.5 end)

    :meck.new(Growth.LoadReference, [:passthrough])
    :meck.expect(Growth.LoadReference, :load_data, fn _, _ ->
      {:ok, %{
        l: 1.0,
        m: 10.0,
        s: 0.1,
        sd0: 10.0,
        sd1: 11.0,
        sd2: 12.0,
        sd3: 13.0,
        sd1neg: 9.0,
        sd2neg: 8.0,
        sd3neg: 7.0
      }}
    end)

    child = %Child{
      name: "Joana",
      birthday: ~D[2022-01-01],
      gender: "female",
      measure_date: ~D[2024-01-01],
      age_in_months: 24
    }

    measure = %Measure{
      weight: 12.0,
      height: 85.0,
      head_circumference: 46.0,
      bmi: 16.6,
      child: child
    }

    result = Calculate.results(measure, child)

    assert is_map(result.results)
    assert result.results.bmi_result[:zscore] == 0.5
    assert result.results.weight_result[:percentile] == 69.0
    assert result.results.height_result[:sd1neg] == 9.0
    assert result.results.head_circumference_result[:sd3] == 13.0
  end

  describe "calculate_result/3 fallback" do
    test "returns 'no results' when measurement is not numeric" do
      result =
        Calculate.calculate_result("invalid", :weight, %Child{
          age_in_months: 24,
          gender: "male",
          birthday: ~D[2022-01-01],
          name: "A"
        })

      assert result == "no results"
    end
  end
end
