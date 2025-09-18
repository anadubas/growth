defmodule Growth.MeasureTest do
  use ExUnit.Case, async: true

  alias Growth.Child
  alias Growth.Measure

  describe "new/2" do
    setup do
      {:ok, child} =
        Child.new(%{
          name: "Leo",
          gender: "male",
          birthday: ~D[2020-01-01]
        })

      %{child: child}
    end

    test "creates a Measure struct with BMI and results", %{child: child} do
      attrs = %{
        weight: 16.0,
        height: 100.0,
        head_circumference: 49.0
      }

      {:ok, measure} = Measure.new(attrs, child)

      assert measure.weight == 16.0
      assert measure.height == 100.0
      assert measure.head_circumference == 49.0
      assert is_float(measure.bmi)
      assert is_map(measure.results)
      assert Map.has_key?(measure.results, :bmi)
    end

    test "sets BMI to 'no measure' if weight or height is missing", %{child: child} do
      attrs = %{
        weight: nil,
        height: 100.0,
        head_circumference: nil
      }

      {:ok, measure} = Measure.new(attrs, child)

      assert measure.bmi == "no measure"
    end
  end
end
