defmodule Growth.PromExPlugin do
  @moduledoc """
  A PromEx plugin for capturing custom application metrics for the Growth application.

  This plugin captures the following metrics:

  ## Event Metrics

  These metrics are captured from Telemetry events emitted by the application.

  - `[:growth, :user_journey, :children_created, :total]` (Counter): Total number of children profiles created.
    - Tags: `[:gender]`
  - `[:growth, :user_journey, :measures_submitted, :total]` (Counter): Total number of growth measures submitted.
    - Tags: `[:gender, :has_weight, :has_height, :has_bmi, :has_head_circumference]`
  - `[:growth, :calculation, :duration, :milliseconds]` (Distribution): Duration of growth calculations.
    - Tags: `[:gender, :success]`
  - `[:growth, :calculation, :measure, :duration, :milliseconds]` (Distribution): Duration of individual measure calculations.
    - Tags: `[:data_type, :success, :gender]`
  - `[:growth, :reference_data, :load, :duration, :milliseconds]` (Distribution): Duration of reference data loading.
    - Tags: `[:data_type, :success]`
  - `[:growth, :reference_data, :chart, :duration, :milliseconds]` (Distribution): Duration of reference data chart generation.
    - Tags: `[:data_type, :success]`
  """

  use PromEx.Plugin

  alias PromEx.MetricTypes

  @impl true
  def event_metrics(_opts) do
    MetricTypes.Event.build(
      :growth_event_metrics,
      [
        counter(
          [:growth, :user_journey, :children_created, :total],
          event_name: [:growth, :child, :created],
          description: "Total number of children profiles created",
          tags: [:gender]
        ),
        counter(
          [:growth, :user_journey, :measures_submitted, :total],
          event_name: [:growth, :measure, :submitted],
          description: "Total number of growth measures submitted",
          tags: [:gender, :has_weight, :has_height, :has_bmi, :has_head_circumference]
        ),
        distribution(
          [:growth, :calculation, :duration, :milliseconds],
          event_name: [:growth, :calculation, :stop],
          description: "Duration of growth calculations",
          measurement: :duration,
          reporter_options: [buckets: [1, 5, 10, 25, 50, 100, 250, 500, 1000, 2500]],
          tags: [:gender, :success],
          unit: {:native, :millisecond}
        ),
        distribution(
          [:growth, :calculation, :measure, :duration, :milliseconds],
          event_name: [:growth, :calculation, :measure, :stop],
          description: "Duration of individual measure calculations",
          measurement: :duration,
          reporter_options: [buckets: [1, 2, 5, 10, 25, 50, 100]],
          tags: [:data_type, :success, :gender],
          unit: {:native, :millisecond}
        ),
        distribution(
          [:growth, :reference_data, :load, :duration, :milliseconds],
          event_name: [:growth, :reference_data, :load, :stop],
          description: "Duration of reference data loading",
          measurement: :duration,
          reporter_options: [buckets: [1, 5, 10, 25, 50, 100]],
          tags: [:data_type, :success],
          unit: {:native, :millisecond}
        ),
        distribution(
          [:growth, :reference_data, :chart, :duration, :milliseconds],
          event_name: [:growth, :reference_data, :chart, :stop],
          description: "Duration of reference data chart generation",
          measurement: :duration,
          reporter_options: [buckets: [1, 5, 10, 25, 50, 100]],
          tags: [:data_type, :success],
          unit: {:native, :millisecond}
        )
      ]
    )
  end
end
