defmodule Growth.PromExPlugin do
  @moduledoc """
  Custom PromEx plugin for Growth application metrics.
  """

  use PromEx.Plugin

  @impl true
  def event_metrics(_opts) do
    [
      # User Journey Metrics
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

      # Calculation Performance Metrics
      distribution(
        [:growth, :calculation, :duration, :milliseconds],
        event_name: [:growth, :calculation, :stop],
        description: "Duration of growth calculations",
        reporter_options: [buckets: [1, 5, 10, 25, 50, 100, 250, 500, 1000, 2500]],
        tags: [:gender, :success]
      ),

      distribution(
        [:growth, :calculation, :measure_duration, :milliseconds],
        event_name: [:growth, :calculation, :measure, :stop],
        description: "Duration of individual measure calculations",
        reporter_options: [buckets: [1, 2, 5, 10, 25, 50, 100]],
        tags: [:data_type, :success, :gender]
      ),

      # Data Loading Performance
      distribution(
        [:growth, :reference_data, :load_duration, :milliseconds],
        event_name: [:growth, :reference_data, :load, :stop],
        description: "Duration of reference data loading",
        reporter_options: [buckets: [1, 5, 10, 25, 50, 100]],
        tags: [:data_type, :success]
      )
    ]
  end

  @impl true
  def polling_metrics(_opts) do
    [
      # Business Logic Gauges
      last_value(
        [:growth, :reference_data, :cache_size, :bytes],
        {Growth.LoadReference, :cache_size, []},
        description: "Size of reference data cache in bytes"
      ),

      gauge(
        [:growth, :calculations, :active, :count],
        {__MODULE__, :active_calculations, []},
        description: "Number of currently running calculations"
      )
    ]
  end

  def active_calculations do
    # Custom logic to count active calculations
    # This would track spans in progress
    0
  end
end
