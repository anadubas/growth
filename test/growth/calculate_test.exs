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
    child = %Child{
      name: "Joana",
      birthday: ~D[2022-01-01],
      gender: "female",
      measure_date: ~D[2024-01-01],
      age_in_months: Calculate.age_in_months(~D[2022-01-01], ~D[2024-01-01]),
      age_in_decimal: Calculate.in_months_decimal(~D[2022-01-01], ~D[2024-01-01])
    }

    measure = %Measure{
      weight: 12.8,
      height: 88.7,
      head_circumference: 47.0,
      bmi: 16.27,
      child: child
    }

    result = Calculate.results(measure, child)

    assert is_map(result.results)
    assert_in_delta result.results.bmi[:zscore], 0.6038, 0.0001
    assert_in_delta result.results.weight[:percentile], 84.40, 0.01
    assert result.results.height[:sd1neg] == 82.3
    assert result.results.head_circumference[:sd3] == 51.2
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
