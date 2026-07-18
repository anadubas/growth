defmodule Growth.ChildTest do
  use ExUnit.Case, async: true

  alias Growth.Child

  describe "new/1" do
    test "successfully creates a child struct with calculated age" do
      birthday = ~D[2020-01-01]

      {:ok, child} =
        Child.new(%{
          name: "Tom",
          gender: "male",
          birthday: birthday
        })

      assert child.name == "Tom"
      assert child.gender == "male"
      assert child.birthday == birthday
    end
  end
end
