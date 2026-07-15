defmodule Growth.ChildTest do
  use ExUnit.Case, async: true

  alias Growth.Child

  describe "new/1" do
    test "successfully creates a child struct with calculated age" do
      birthday = ~D[2020-01-01]
      measure_date = ~D[2025-01-01]

      {:ok, child} =
        Child.new(%{
          name: "Tom",
          gender: "male",
          birthday: birthday,
          measure_date: measure_date
        })

      assert child.name == "Tom"
      assert child.gender == "male"
      assert child.birthday == birthday
      assert child.measure_date == measure_date
      assert is_integer(child.age_in_months)
      assert child.age_in_months == 60
      assert child.age_in_decimal == 60.02
    end
  end
end
