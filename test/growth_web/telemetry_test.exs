defmodule GrowthWeb.TelemetryTest do
  use ExUnit.Case, async: true

  alias Growth.Calculate
  alias Growth.Child
  alias Growth.Measure

  setup do
    # Attach a handler for the test process
    :telemetry.attach(
      "telemetry-test-handler",
      [:growth, :child, :created],
      &handle_event/4,
      self()
    )

    :telemetry.attach(
      "telemetry-test-handler-calc",
      [:growth, :calculation, :start],
      &handle_event/4,
      self()
    )

    :telemetry.attach(
      "telemetry-test-handler-calc-stop",
      [:growth, :calculation, :stop],
      &handle_event/4,
      self()
    )

    :telemetry.attach(
      "telemetry-test-handler-measure",
      [:growth, :calculation, :measure, :start],
      &handle_event/4,
      self()
    )

    :telemetry.attach(
      "telemetry-test-handler-measure-stop",
      [:growth, :calculation, :measure, :stop],
      &handle_event/4,
      self()
    )

    :telemetry.attach(
      "telemetry-test-handler-ref",
      [:growth, :reference_data, :load, :start],
      &handle_event/4,
      self()
    )

    :telemetry.attach(
      "telemetry-test-handler-ref-stop",
      [:growth, :reference_data, :load, :stop],
      &handle_event/4,
      self()
    )

    on_exit(fn ->
      :telemetry.detach("telemetry-test-handler")
      :telemetry.detach("telemetry-test-handler-calc")
      :telemetry.detach("telemetry-test-handler-calc-stop")
      :telemetry.detach("telemetry-test-handler-measure")
      :telemetry.detach("telemetry-test-handler-measure-stop")
      :telemetry.detach("telemetry-test-handler-ref")
      :telemetry.detach("telemetry-test-handler-ref-stop")
    end)

    :ok
  end

  # Helper to handle events and send them to the test process
  def handle_event(event, measurements, metadata, pid) do
    send(pid, {event, measurements, metadata})
  end

  test "emits :child, :created event on success" do
    child_attrs = %{name: "Test", gender: "female", birthday: ~D[2023-01-01]}
    {:ok, _child} = Child.new(child_attrs)

    assert_receive {
      [:growth, :child, :created],
      %{count: 1},
      %{age_in_months: _, gender: "female", measure_date: _}
    }
  end

  test "emits span events for successful calculation" do
    child = %Child{name: "Test", birthday: ~D[2023-01-01], gender: "female", age_in_months: 20}
    measure = %Measure{weight: 10, height: 80, bmi: 15.6, head_circumference: 45}

    Calculate.results(measure, child)

    # Assert start event
    assert_receive {
      [:growth, :calculation, :start],
      %{system_time: _},
      %{age_in_months: 20, gender: "female", measure_date: _}
    }

    # Assert stop event
    assert_receive {
      [:growth, :calculation, :stop],
      %{duration: _},
      %{age_in_months: 20, child_gender: "female", success: true, has_weight_result: true}
    }
  end

  test "emits span events for failed data loading" do
    # Using an age for which there is no reference data to force an error
    child = %Child{name: "Test", birthday: ~D[2023-01-01], gender: "female", age_in_months: 999}
    measure = %Measure{weight: 10, height: 80, bmi: 15.6, head_circumference: 45}

    Calculate.results(measure, child)

    # Assert start event for the outer calculation
    assert_receive {
      [:growth, :calculation, :start],
      %{system_time: _},
      %{age_in_months: 999, gender: "female", measure_date: _}
    }

    # Assert events for all four measurement types
    for data_type <- [:weight, :height, :bmi, :head_circumference] do
      assert_receive {
        [:growth, :calculation, :measure, :start],
        %{system_time: _},
        %{age_in_months: 999, child_gender: "female", data_type: ^data_type, measure_date: _}
      }

      assert_receive {
        [:growth, :reference_data, :load, :start],
        %{system_time: _},
        %{age_in_months: 999, child_gender: "female", data_type: ^data_type, measure_date: _}
      }

      assert_receive {
        [:growth, :reference_data, :load, :stop],
        %{duration: _},
        %{age_in_months: 999, child_gender: "female", data_type: ^data_type, success: _}
      }

      assert_receive {
        [:growth, :calculation, :measure, :stop],
        %{duration: _},
        %{age_in_months: 999, child_gender: "female", data_type: ^data_type, success: _}
      }
    end

    # Assert stop for the outer calculation
    assert_receive {
      [:growth, :calculation, :stop],
      %{duration: _},
      %{age_in_months: 999, child_gender: "female", success: true, has_weight_result: _}
    }
  end
end
