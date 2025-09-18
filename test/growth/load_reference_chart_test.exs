defmodule Growth.LoadReferenceChartTest do
  use ExUnit.Case, async: false

  setup_all do
    table_name = :__unique_measure_for_test__
    :ets.new(table_name, [:set, :public, :named_table, read_concurrency: true])

    # Simple data where values increase linearly with age for easy testing of interpolation
    test_data = [
      {{:boy, :month, 1}, %{age: 1, month: 1, gender: :boy, l: 1.0, m: 2.0, s: 3.0}},
      {{:boy, :month, 2}, %{age: 2, month: 2, gender: :boy, l: 2.0, m: 4.0, s: 6.0}},
      {{:boy, :month, 3}, %{age: 3, month: 3, gender: :boy, l: 3.0, m: 6.0, s: 9.0}},
      {{:boy, :month, 4}, %{age: 4, month: 4, gender: :boy, l: 4.0, m: 8.0, s: 12.0}},
      {{:girl, :month, 1}, %{age: 1, month: 1, gender: :girl, l: 1.1, m: 2.2, s: 3.3}}
    ]

    for {key, value} <- test_data do
      :ets.insert(table_name, {key, value})
    end

    on_exit(fn ->
      if :ets.info(table_name) != :undefined do
        :ets.delete(table_name)
      end
    end)

    %{table_name: table_name}
  end

  describe "load_data/5" do
    test "loads a range of data without interpolation", %{table_name: table_name} do
      {:ok, result} = Growth.LoadReferenceChart.load_data(table_name, "boy", 2, 1)
      assert length(result) == 3
      assert Enum.map(result, & &1.age) == [1, 2, 3]
      assert Enum.map(result, & &1.m) == [2.0, 4.0, 6.0]
    end

    test "loads all data for a gender with :inf range", %{table_name: table_name} do
      {:ok, result} = Growth.LoadReferenceChart.load_data(table_name, "boy", 1, :inf)
      assert length(result) == 4
      assert Enum.map(result, & &1.age) == [1, 2, 3, 4]
    end

    test "returns an error when no data is found in the range", %{table_name: table_name} do
      assert {:error, "no data found for #{table_name}, boy, age 10"} ==
               Growth.LoadReferenceChart.load_data(table_name, "boy", 10, 1)
    end

    test "handles ranges at the edge of the data", %{table_name: table_name} do
      # Range is [0, 2], but data starts at 1. Should return for ages 1, 2.
      {:ok, result} = Growth.LoadReferenceChart.load_data(table_name, "boy", 1, 1)
      assert length(result) == 2
      assert Enum.map(result, & &1.age) == [1, 2]

      # Range is [3, 5], but data ends at 4. Should return for ages 3, 4.
      {:ok, result_upper} = Growth.LoadReferenceChart.load_data(table_name, "boy", 4, 1)
      assert length(result_upper) == 2
      assert Enum.map(result_upper, & &1.age) == [3, 4]
    end

    test "loads data with one subdivision (interpolation)", %{table_name: table_name} do
      {:ok, result} = Growth.LoadReferenceChart.load_data(table_name, "boy", 2, 1, 1)

      # Expected points for range [1, 3]: 1, 1.5, 2, 2.5, 3
      assert length(result) == 5
      assert Enum.map(result, & &1.age) == [1, 1.5, 2, 2.5, 3]

      # Check interpolated point between 1 and 2
      interpolated_point1 = Enum.find(result, &(&1.age == 1.5))
      # (2.0 + 4.0) / 2
      assert interpolated_point1.m == 3.0

      # Check interpolated point between 2 and 3
      interpolated_point2 = Enum.find(result, &(&1.age == 2.5))
      # (4.0 + 6.0) / 2
      assert interpolated_point2.m == 5.0
    end

    test "loads data with two subdivisions (interpolation)", %{table_name: table_name} do
      # Range is [1, 2]
      {:ok, result} = Growth.LoadReferenceChart.load_data(table_name, "boy", 1, 1, 2)

      # Expected points for range [1, 2]: 1, 1.333..., 1.666..., 2
      assert length(result) == 4
      ages = Enum.map(result, & &1.age)
      expected_ages = [1, 1 + 1 / 3, 1 + 2 / 3, 2]
      Enum.zip(ages, expected_ages) |> Enum.each(fn {a, e} -> assert_in_delta a, e, 0.001 end)

      # Check interpolated points between 1 and 2
      point1 = Enum.at(result, 1)
      assert_in_delta point1.m, 2.0 + (4.0 - 2.0) * (1 / 3), 0.001

      point2 = Enum.at(result, 2)
      assert_in_delta point2.m, 2.0 + (4.0 - 2.0) * (2 / 3), 0.001
    end

    test "does not interpolate if only one data point is found", %{table_name: table_name} do
      # Range is [0, 1], so only age 1 is found.
      {:ok, result} = Growth.LoadReferenceChart.load_data(table_name, "boy", 0, 1, 2)
      assert length(result) == 1
      assert hd(result).age == 1
    end
  end
end
