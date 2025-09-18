defmodule Growth.ChildTest do
  use ExUnit.Case, async: true

  alias Growth.Child

  describe "new/1" do
    test "successfully creates a child struct with calculated age" do
      birthday = ~D[2022-01-01]
      today = Date.utc_today()

      {:ok, child} =
        Child.new(%{
          name: "Tom",
          gender: "male",
          birthday: birthday
        })

      assert child.name == "Tom"
      assert child.gender == "male"
      assert child.birthday == birthday
      assert child.measure_date == today
      assert is_integer(child.age_in_months)
      assert child.age_in_months >= 0
    end
  end

  describe "add_age_in_months/1" do
    test "calculates age based on birthday and measure date" do
      birthday = ~D[2020-01-01]
      measure_date = ~D[2025-01-01]

      child = %Child{
        name: "Jane",
        gender: "female",
        birthday: birthday,
        measure_date: measure_date
      }

      assert %Child{age_in_months: 60} = Child.add_age_in_months(child)
    end
  end
end
