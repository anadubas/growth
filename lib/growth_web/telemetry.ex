defmodule GrowthWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics
  require Logger

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    # Attach a logger for all our events.
    # This is useful for development and debugging.
    :ok = attach_events()

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.exception.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.socket_connected.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel_joined.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel_handled_in.duration",
        tags: [:event],
        unit: {:native, :millisecond}
      ),

      # == Growth Metrics ==

      # User Journey Events
      counter("growth.child.created.count"),
      counter("growth.measure.submitted.count"),

      # Business Logic Span Events
      summary("growth.calculation.stop.duration",
        unit: {:native, :millisecond}
      ),
      counter("growth.calculation.stop.count"),
      summary("growth.calculation.measure.stop.duration",
        # tags: [:data_type, :success],
        unit: {:native, :millisecond}
      ),
      summary("growth.reference_data.load.stop.duration",
        # tags: [:data_type, :success],
        unit: {:native, :millisecond}
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {GrowthWeb, :count_users, []}
    ]
  end

  defp attach_events do
    case Application.get_env(:growth, :env) do
      :dev ->
        :telemetry.attach_many("growth-logger", all_events(), &handle_event/4, nil)

      _ ->
        :ok
    end
  end

  defp all_events do
    [
      # User Journey
      [:growth, :child, :created],
      [:growth, :measure, :submitted],
      # [:growth, :results, :viewed],
      # [:growth, :form, :reset],
      # Spans (start, stop, exception)
      [:growth, :calculation, :start],
      [:growth, :calculation, :stop],
      [:growth, :calculation, :measure, :start],
      [:growth, :calculation, :measure, :stop],
      [:growth, :reference_data, :load, :start],
      [:growth, :reference_data, :load, :stop]
    ]
  end

  defp handle_event(event, measurements, metadata, _config) do
    Logger.info("[Telemetry] #{inspect(event)}
  Measurements: #{inspect(measurements)}
  Metadata: #{inspect(metadata)}")
  end
end
