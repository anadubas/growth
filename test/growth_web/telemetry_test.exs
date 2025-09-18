defmodule GrowthWeb.TelemetryTest do
  use ExUnit.Case, async: true

  alias Growth.Calculate
  alias Growth.Child
  alias Growth.LoadReferenceChart
  alias Growth.Measure

  test "emits :child, :created event on success" do
    ref = :telemetry_test.attach_event_handlers(self(), [[:growth, :child, :created]])

    child_attrs = %{name: "Test", gender: "female", birthday: ~D[2023-01-01]}

    assert {:ok, %Child{age_in_months: age_in_months, measure_date: measure_date}} =
             Child.new(child_attrs)

    assert_received(
      {[:growth, :child, :created], ^ref, %{count: 1},
       %{age_in_months: ^age_in_months, gender: "female", measure_date: ^measure_date}}
    )
  end

  test "emits span events for successful calculation" do
    ref =
      :telemetry_test.attach_event_handlers(self(), [
        [:growth, :calculation, :start],
        [:growth, :calculation, :stop]
      ])

    child = %Child{
      name: "Test",
      birthday: ~D[2023-01-01],
      measure_date: ~D[2024-10-01],
      gender: "female",
      age_in_months: 20
    }

    measure = %Measure{weight: 3.8, height: 52.3, bmi: 13.89, head_circumference: 35.8}

    Calculate.results(measure, child)

    assert_received(
      {[:growth, :calculation, :start], ^ref, %{monotonic_time: _},
       %{age_in_months: 20, gender: "female", measure_date: ~D[2024-10-01]}}
    )

    assert_received(
      {[:growth, :calculation, :stop], ^ref, %{count: 1, duration: _, monotonic_time: _},
       %{
         age_in_months: 20,
         gender: "female",
         has_bmi_result: true,
         has_head_circumference_result: true,
         has_height_result: true,
         has_weight_result: true,
         measure_date: ~D[2024-10-01],
         success: true
       }}
    )
  end

  test "emits span events for successful measure calculation and data loading" do
    ref =
      :telemetry_test.attach_event_handlers(self(), [
        [:growth, :calculation, :measure, :start],
        [:growth, :reference_data, :load, :start],
        [:growth, :reference_data, :load, :stop],
        [:growth, :calculation, :measure, :stop]
      ])

    child = %Child{
      name: "Test",
      birthday: ~D[2023-01-01],
      measure_date: ~D[2024-10-01],
      gender: "female",
      age_in_months: 20
    }

    measure = %Measure{weight: 3.8, height: 52.3, bmi: 13.89, head_circumference: 35.8}

    Calculate.results(measure, child)

    for data_type <- [:weight, :height, :bmi, :head_circumference] do
      assert_received(
        {[:growth, :calculation, :measure, :start], ^ref, %{monotonic_time: _},
         %{
           age_in_months: 20,
           data_type: ^data_type,
           gender: "female",
           measure_date: ~D[2024-10-01]
         }}
      )

      assert_received(
        {[:growth, :reference_data, :load, :start], ^ref, %{monotonic_time: _},
         %{
           age_in_months: 20,
           data_type: ^data_type,
           gender: "female",
           measure_date: ~D[2024-10-01]
         }}
      )

      assert_received(
        {[:growth, :reference_data, :load, :stop], ^ref, %{duration: _, monotonic_time: _},
         %{
           age_in_months: 20,
           data_type: ^data_type,
           gender: "female",
           measure_date: ~D[2024-10-01],
           success: true
         }}
      )

      assert_received(
        {[:growth, :calculation, :measure, :stop], ^ref, %{duration: _, monotonic_time: _},
         %{
           age_in_months: 20,
           data_type: ^data_type,
           gender: "female",
           measure_date: ~D[2024-10-01],
           success: true
         }}
      )
    end
  end

  test "emits span events for successful chart data loading" do
    ref =
      :telemetry_test.attach_event_handlers(self(), [
        [:growth, :reference_data, :chart, :start],
        [:growth, :reference_data, :chart, :stop]
      ])

    child = %Child{
      name: "Test",
      birthday: ~D[2023-01-01],
      measure_date: ~D[2024-10-01],
      gender: "female",
      age_in_months: 20
    }

    for data_type <- [:weight, :height, :bmi, :head_circumference] do
      LoadReferenceChart.load_data(
        data_type,
        child.gender,
        child.age_in_months
      )

      assert_received(
        {[:growth, :reference_data, :chart, :start], ^ref, %{monotonic_time: _},
         %{
           age_in_months: 20,
           data_type: ^data_type,
           gender: "female"
         }}
      )

      assert_received(
        {[:growth, :reference_data, :chart, :stop], ^ref, %{duration: _, monotonic_time: _},
         %{
           age_in_months: 20,
           data_type: ^data_type,
           gender: "female",
           success: true
         }}
      )
    end
  end
end
