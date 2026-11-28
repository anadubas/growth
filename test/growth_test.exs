defmodule GrowthTest do
  use ExUnit.Case, async: true

  alias Growth.Child
  alias Growth.Measure

  setup do
    {:ok, child} =
      Child.new(%{
        name: "Leo",
        gender: "male",
        birthday: ~D[2020-01-01]
      })

    %{child: child}
  end

  describe "child_measures/2" do
    test "builds a measure per attrs entry", %{child: child} do
      attrs_list = [
        %{measure_date: ~D[2024-01-01], weight: 14.0, height: 95.0},
        %{measure_date: ~D[2025-01-01], weight: 16.0, height: 100.0}
      ]

      assert {:ok, [%Measure{} = first, %Measure{} = second]} =
               Growth.child_measures(attrs_list, child)

      assert first.measure_date == ~D[2024-01-01]
      assert second.measure_date == ~D[2025-01-01]
      assert first.age_in_months < second.age_in_months
      assert is_map(first.results)
      assert is_map(second.results)
    end

    test "returns an empty list for an empty list", %{child: child} do
      assert {:ok, []} == Growth.child_measures([], child)
    end

    test "aggregates per-row errors by index, keeping valid rows reported too", %{
      child: child
    } do
      attrs_list = [
        %{measure_date: ~D[2024-01-01], weight: 14.0},
        %{measure_date: ~D[2019-01-01], weight: 10.0},
        %{measure_date: ~D[2025-01-01], weight: 16.0}
      ]

      assert {:error, errors} = Growth.child_measures(attrs_list, child)

      assert %{1 => [%Zoi.Error{path: [:measure_date]}]} = errors
      refute Map.has_key?(errors, 0)
      refute Map.has_key?(errors, 2)
    end

    test "rejects duplicated measure_date on the later occurrences", %{child: child} do
      attrs_list = [
        %{measure_date: ~D[2024-01-01], weight: 14.0},
        %{measure_date: ~D[2024-06-01], weight: 15.0},
        %{measure_date: ~D[2024-01-01], weight: 16.0}
      ]

      assert {:error, %{2 => [%Zoi.Error{path: [:measure_date], message: message}]}} =
               Growth.child_measures(attrs_list, child)

      assert message =~ "duplicada"
    end

    test "rejects lists longer than max_measures/0", %{child: child} do
      attrs_list =
        for month <- 1..(Growth.max_measures() + 1) do
          %{measure_date: Date.add(~D[2020-02-01], month * 30), weight: 14.0}
        end

      assert {:error, %{max_measures: [%Zoi.Error{message: message}]}} =
               Growth.child_measures(attrs_list, child)

      assert message =~ "máximo de 12 medidas"
    end
  end
end
