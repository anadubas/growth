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

  describe "calculate" do
    test "returns a Measure struct with results" do
      child = %Child{
        name: "Joana",
        birthday: ~D[2022-01-01],
        gender: "female"
      }

      measure = %Measure{
        measure_date: ~D[2024-01-01],
        age_in_months: Calculate.age_in_months(~D[2022-01-01], ~D[2024-01-01]),
        age_in_decimal: Calculate.in_months_decimal(~D[2022-01-01], ~D[2024-01-01]),
        weight: 12.8,
        height: 88.7,
        head_circumference: 47.0,
        bmi: 16.27,
        child: child
      }

      result = Calculate.results(measure)

      assert is_map(result.results)
      assert_in_delta result.results.bmi.zscore, 0.6038, 0.0001
      assert_in_delta result.results.weight.percentile, 84.40, 0.01
      assert result.results.height.sd1neg == 82.3
      assert result.results.head_circumference.sd3 == 51.2
    end

    test "returns a Measure struct with results for age greater than 5 years" do
      birthday = ~D[2021-01-16]
      measure_date = ~D[2026-07-16]

      child =
        %Child{
          name: "Jane",
          birthday: birthday,
          gender: "female"
        }

      measure =
        %Measure{
          measure_date: measure_date,
          age_in_months: Calculate.age_in_months(birthday, measure_date),
          age_in_decimal: Calculate.in_months_decimal(birthday, measure_date),
          weight: 19.0,
          height: 112.0,
          head_circumference: 43.0,
          bmi: 15.15,
          child: child
        }

      result = Calculate.results(measure)

      assert is_map(result.results)
      assert_in_delta result.results.bmi.zscore, -0.06335, 0.00001
      assert_in_delta result.results.weight.percentile, 50.66, 0.001
      assert result.results.height.sd1neg == 106.767
      refute result.results.head_circumference.available?
    end

    test "returns a Measure struct with results for age greater than 10 years" do
      birthday = ~D[2016-01-16]
      measure_date = ~D[2026-07-16]

      child =
        %Child{
          name: "Jane",
          birthday: birthday,
          gender: "female"
        }

      measure =
        %Measure{
          measure_date: measure_date,
          age_in_months: Calculate.age_in_months(birthday, measure_date),
          age_in_decimal: Calculate.in_months_decimal(birthday, measure_date),
          weight: 33.3,
          height: 141.3,
          head_circumference: 45.0,
          bmi: 16.68,
          child: child
        }

      result = Calculate.results(measure)

      assert is_map(result.results)
      assert_in_delta result.results.bmi.zscore, -0.08725, 0.00001
      assert result.results.height.sd1neg == 134.754
      refute result.results.weight.available?
      refute result.results.head_circumference.available?
    end

    test "returns a Measure struct with results for age around 19 years" do
      birthday = ~D[2007-07-16]
      measure_date = ~D[2026-07-16]

      child =
        %Child{
          name: "Jane",
          birthday: birthday,
          gender: "female"
        }

      measure =
        %Measure{
          measure_date: measure_date,
          age_in_months: Calculate.age_in_months(birthday, measure_date),
          age_in_decimal: Calculate.in_months_decimal(birthday, measure_date),
          weight: 57.26,
          height: 163.2,
          head_circumference: 45.0,
          bmi: 21.49,
          child: child
        }

      result = Calculate.results(measure)

      assert is_map(result.results)
      assert_in_delta result.results.bmi.zscore, 0.02034, 0.000001
      assert result.results.height.sd1neg == 156.614
      refute result.results.weight.available?
      refute result.results.head_circumference.available?
    end
  end

  describe "calculate_result/3" do
    test "returns unavailable result when measurement is not numeric" do
      result =
        Calculate.calculate_result(:weight, %Measure{
          weight: "invalid",
          age_in_months: 24,
          child: %Child{gender: "male", birthday: ~D[2022-01-01], name: "A"}
        })

      refute result.available?
    end
  end
end
