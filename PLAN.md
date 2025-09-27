# REVISED: Custom Observability Implementation Plan

Based on comprehensive analysis of the existing telemetry infrastructure, here's an updated implementation plan that **enhances existing capabilities** rather than rebuilding them.

## Current Telemetry Analysis

**✅ STRONG Foundation Already Built:**
- **User Journey Events**: `[:growth, :child, :created]`, `[:growth, :measure, :submitted]`
- **Business Logic Spans**: Properly implemented `:telemetry.span/3` in:
  - `Growth.Calculate.results/2` - main calculation span with metadata
  - `Growth.Calculate.calculate_result/3` - individual measure calculation
  - `Growth.LoadReference` - reference data loading spans
  - `Growth.LoadReferenceChart` - chart data loading spans
- **Telemetry Metrics**: Well-structured metrics in `GrowthWeb.Telemetry.metrics/0`
- **OpenTelemetry Dependencies**: All required OTel packages already in `mix.exs`

**📊 Current PromEx Setup:**
- Basic PromEx configuration with Phoenix, Beam, and LiveView plugins
- Ready for custom metrics plugins integration
- `Growth.PromEx` module prepared for enhancement
- Dashboards infrastructure available

## Implementation Strategy

### Phase 3A: Enhanced Telemetry-to-OpenTelemetry Bridge

**Goal**: Bridge existing telemetry spans to OpenTelemetry while preserving all current functionality.

#### Step 3A.1: Bridge Configuration (Dependencies Ready)
All OpenTelemetry dependencies already installed in `mix.exs`.

#### Step 3A.2: Integrate Bridges into Existing Telemetry Setup
Update `lib/growth_web/telemetry.ex` in the `attach_events/0` function. Instead of a separate `setup_otel_bridges` function, we will attach handlers that create OpenTelemetry spans.

```elixir
defp attach_events do
  # Attach handlers to bridge telemetry events to OpenTelemetry spans
  :telemetry.attach("otel-span-bridge-calculation", [:growth, :calculation, :start], &handle_span_start/4, nil)
  :telemetry.attach("otel-span-bridge-calculation-stop", [:growth, :calculation, :stop], &handle_span_stop/4, nil)
  :telemetry.attach("otel-span-bridge-calculation-exception", [:growth, :calculation, :exception], &handle_span_exception/4, nil)

  :telemetry.attach("otel-span-bridge-measure-start", [:growth, :calculation, :measure, :start], &handle_span_start/4, nil)
  :telemetry.attach("otel-span-bridge-measure-stop", [:growth, :calculation, :measure, :stop], &handle_span_stop/4, nil)
  :telemetry.attach("otel-span-bridge-measure-exception", [:growth, :calculation, :measure, :exception], &handle_span_exception/4, nil)

  :telemetry.attach("otel-span-bridge-reference-load-start", [:growth, :reference_data, :load, :start], &handle_span_start/4, nil)
  :telemetry.attach("otel-span-bridge-reference-load-stop", [:growth, :reference_data, :load, :stop], &handle_span_stop/4, nil)
  :telemetry.attach("otel-span-bridge-reference-load-exception", [:growth, :reference_data, :load, :exception], &handle_span_exception/4, nil)

  :telemetry.attach("otel-span-bridge-reference-chart-start", [:growth, :reference_data, :chart, :start], &handle_span_start/4, nil)
  :telemetry.attach("otel-span-bridge-reference-chart-stop", [:growth, :reference_data, :chart, :stop], &handle_span_stop/4, nil)
  :telemetry.attach("otel-span-bridge-reference-chart-exception", [:growth, :reference_data, :chart, :exception], &handle_span_exception/4, nil)


  case Application.get_env(:growth, :env) do
    :dev ->
      :telemetry.attach_many("growth-logger", all_events(), &handle_event/4, nil)
    _ ->
      :ok
  end
end

defp handle_span_start(event_name, _measurements, metadata, _config) do
  :opentelemetry_telemetry.start_telemetry_span(event_name, metadata)
end

defp handle_span_stop(_event_name, _measurements, metadata, _config) do
  :opentelemetry_telemetry.end_telemetry_span(metadata)
end

defp handle_span_exception(_event_name, _measurements, metadata, _config) do
  :opentelemetry_telemetry.end_telemetry_span(metadata)
end
```

#### Step 3A.3: Enhance Event Attributes for OpenTelemetry
Update existing telemetry events with OpenTelemetry-compatible attribute naming:

```elixir
# In lib/growth/child.ex - enhance existing execute call
:telemetry.execute([:growth, :child, :created], %{count: 1}, %{
  # Existing attributes (keep these)
  age_in_months: age_in_months,
  gender: gender,
  measure_date: measure_date,
  # Add OpenTelemetry-compatible attributes
  "child.gender" => gender,
  "child.age_months" => age_in_months,
  "child.birthday" => to_string(birthday),
  "measure.date" => to_string(measure_date),
  "otel.kind" => "event"
})

# In lib/growth/measure.ex - enhance existing execute call
:telemetry.execute([:growth, :measure, :submitted], %{count: 1}, %{
  # Existing attributes (keep these)
  age_in_months: child.age_in_months,
  gender: child.gender,
  measure_date: child.measure_date,
  has_weight: not is_nil(weight),
  has_height: not is_nil(height),
  has_head_circumference: not is_nil(head_circumference),
  # Add OpenTelemetry-compatible attributes
  "measure.weight" => weight,
  "measure.height" => height,
  "measure.bmi" => bmi,
  "measure.head_circumference" => head_circumference,
  "child.gender" => child.gender,
  "child.age_months" => child.age_in_months,
  "otel.kind" => "event"
})
```

### Phase 3B: Enhanced Span Instrumentation (Additive Approach)

**Goal**: Add complementary OpenTelemetry spans to enrich existing telemetry without duplication.

#### Step 3B.1: Add Span Events to Existing Growth.Calculate Module
Enhance existing `:telemetry.span` calls with OpenTelemetry span events:

```elixir
# In lib/growth/calculate.ex - enhance existing results/2 function
def results(growth, child) do
  :telemetry.span(
    [:growth, :calculation],
    metadata,
    fn ->
      # Add OpenTelemetry span events to existing span
      OpenTelemetry.Tracer.add_event("calculation.started", %{
        "input.has_weight" => not is_nil(growth.weight),
        "input.has_height" => not is_nil(growth.height),
        "input.has_bmi" => not is_nil(growth.bmi),
        "input.has_head_circumference" => not is_nil(growth.head_circumference)
      })

      # Existing calculation logic remains the same
      weight_result = calculate_result(weight, :weight, child)
      height_result = calculate_result(height, :height, child)
      bmi_result = calculate_result(bmi, :bmi, child)
      head_circumference_result = calculate_result(head_circumference, :head_circumference, child)

      result = %{
        weight_result: weight_result,
        height_result: height_result,
        bmi_result: bmi_result,
        head_circumference_result: head_circumference_result
      }

      # Add completion event
      OpenTelemetry.Tracer.add_event("calculation.completed", %{
        "results.calculated_measures" => count_successful_results(result),
        "results.has_errors" => has_calculation_errors?(result)
      })

      {result, success_metadata}
    end
  )
end
```

#### Step 3B.2: Add New Instrumentation to Classification Modules
Add OpenTelemetry spans to `Growth.Classify`, `Growth.Zscore`, `Growth.Percentile`:

```elixir
# In lib/growth/classify.ex - add new instrumentation
defmodule Growth.Classify do
  require OpenTelemetry.Tracer

  def calculate(data_type, zscore) do
    OpenTelemetry.Tracer.with_span("growth.classify.calculate", %{
      "classify.data_type" => to_string(data_type),
      "classify.input_zscore" => zscore
    }) do
      result = # ... existing logic

      OpenTelemetry.Tracer.set_attribute("classify.result", result)
      result
    end
  end
end

# In lib/growth/zscore.ex - add new instrumentation
defmodule Growth.Zscore do
  require OpenTelemetry.Tracer

  def calculate(measure, %{l: l, m: m, s: s}) do
    OpenTelemetry.Tracer.with_span("growth.zscore.calculate", %{
      "zscore.measure" => measure,
      "zscore.reference_l" => l,
      "zscore.reference_m" => m,
      "zscore.reference_s" => s
    }) do
      # ... existing calculation logic
    end
  end
end
```

#### Step 3B.3: Add Error Tracking Events
Enhance error handling with OpenTelemetry span status:

```elixir
# In existing telemetry spans, add error tracking
case some_calculation do
  {:ok, result} ->
    OpenTelemetry.Tracer.set_status(:ok)
    {result, success_metadata}

  {:error, reason} ->
    OpenTelemetry.Tracer.record_exception(%RuntimeError{message: to_string(reason)})
    OpenTelemetry.Tracer.set_status(:error, to_string(reason))
    {"no data found", error_metadata}
end
```

### Phase 4A: PromEx Custom Metrics Integration

**Goal**: Create custom PromEx plugin for Growth-specific metrics and integrate with existing setup.

#### Step 4A.1: Create Custom PromEx Plugin
Create `lib/growth/prom_ex_plugin.ex`:

```elixir
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
```

#### Step 4A.2: Integrate with Existing PromEx Configuration
Update existing `plugins/0` function in `lib/growth/prom_ex.ex`:

```elixir
@impl true
def plugins do
  [
    # PromEx built in plugins
    Plugins.Application,
    Plugins.Beam,
    {Plugins.Phoenix, router: GrowthWeb.Router, endpoint: GrowthWeb.Endpoint},
    Plugins.PhoenixLiveView,

    # Add our custom Growth metrics plugin
    Growth.PromExPlugin
  ]
end
```

#### Step 4A.3: Enable Dashboards (Optional)
Update existing `dashboards/0` function if dashboards are needed:

```elixir
@impl true
def dashboards do
  [
    # Enable PromEx built-in dashboards
    {:prom_ex, "application.json"},
    {:prom_ex, "beam.json"},
    {:prom_ex, "phoenix.json"},
    {:prom_ex, "phoenix_live_view.json"}

    # Add custom Growth dashboard when ready
    # {:growth, "/grafana_dashboards/growth_metrics.json"}
  ]
end
```

### Phase 4B: Structured Logging Enhancement with LoggerJSON

**Goal**: Enhance existing JSON logging with trace correlation and OpenTelemetry integration.

#### Step 4B.1: Configure LoggerJSON with Trace Correlation
Update `config/config.exs` to enhance existing `logger_json` setup with OpenTelemetry correlation. The existing configuration in the plan is not correct for `logger_json` v7.

```elixir
# config/config.exs
config :logger,
  backends: [LoggerJSON]

config :logger_json, :backend,
  json_encoder: Jason,
  metadata: [:trace_id, :span_id, :user_id, :request_id],
  formatter: LoggerJSON.Formatters.Basic

# Add OpenTelemetry correlation
config :opentelemetry,
  processors: [
    {:otel_batch_processor, %{
      exporter: {:opentelemetry_exporter, %{}},
      scheduled_delay_ms: 5_000
    }}
  ]
```

#### Step 4B.2: Create Enhanced Structured Logger Module
Create `lib/growth/structured_logger.ex` to work with existing `logger_json`:

```elixir
defmodule Growth.StructuredLogger do
  @moduledoc """
  Structured logging utilities with OpenTelemetry trace correlation.
  Integrates with existing logger_json configuration.
  """

  require Logger
  require OpenTelemetry.Tracer

  @doc """
  Log with trace correlation and structured metadata.
  Leverages existing logger_json setup.
  """
  def log(level, message, metadata \\ %{}) when level in [:debug, :info, :warn, :error] do
    # Get current trace context
    span_ctx = OpenTelemetry.Tracer.current_span_ctx()

    enhanced_metadata =
      metadata
      |> add_trace_correlation(span_ctx)
      |> Map.put(:service_name, "growth-app")
      |> Map.put(:timestamp, DateTime.utc_now())

    # Use standard Logger (logger_json will format as JSON)
    Logger.log(level, message, enhanced_metadata)

    # Also add as OpenTelemetry span event
    add_span_event_if_active(span_ctx, level, message, enhanced_metadata)
  end

  # Convenience functions
  def info(message, metadata \\ %{}), do: log(:info, message, metadata)
  def warn(message, metadata \\ %{}), do: log(:warn, message, metadata)
  def error(message, metadata \\ %{}), do: log(:error, message, metadata)
  def debug(message, metadata \\ %{}), do: log(:debug, message, metadata)

  defp add_trace_correlation(metadata, :undefined), do: metadata
  defp add_trace_correlation(metadata, span_ctx) do
    metadata
    |> Map.put(:trace_id, OpenTelemetry.Span.trace_id(span_ctx))
    |> Map.put(:span_id, OpenTelemetry.Span.span_id(span_ctx))
  end

  defp add_span_event_if_active(:undefined, _level, _message, _metadata), do: :ok
  defp add_span_event_if_active(_span_ctx, level, message, metadata) do
    OpenTelemetry.Tracer.add_event(
      "log.#{level}",
      Map.put(metadata, :message, message)
    )
  end
end
```

#### Step 4B.3: Enhance Business Logic Logging
Update key modules to use structured logging with existing telemetry:

```elixir
# In lib/growth/calculate.ex - enhance existing calculate_result/3
defmodule Growth.Calculate do
  alias Growth.StructuredLogger

  def calculate_result(measure, data_type, child) do
    :telemetry.span([:growth, :calculation, :measure], metadata, fn ->
      StructuredLogger.info("Starting growth calculation", %{
        calculation_data_type: data_type,
        calculation_measure: measure,
        child_age_months: child.age_in_months,
        child_gender: child.gender
      })

      case LoadReference.load_data(data_type, child) do
        {:ok, data} ->
          StructuredLogger.debug("Reference data loaded successfully", %{
            reference_l: data.l,
            reference_m: data.m,
            reference_s: data.s,
            data_type: data_type
          })

          result = # ... existing calculation logic

          StructuredLogger.info("Calculation completed", %{
            result_zscore: result.zscore,
            result_percentile: result.percentile,
            result_classification: result.classification,
            calculation_success: true
          })

          {result, success_metadata}

        {:error, reason} ->
          StructuredLogger.error("Reference data loading failed", %{
            error_reason: to_string(reason),
            calculation_data_type: data_type,
            calculation_success: false
          })

          {"no data found", error_metadata}
      end
    end)
  end
end

# In lib/growth_web/telemetry.ex - enhance existing handle_event/4
defp handle_event(event, measurements, metadata, _config) do
  StructuredLogger.info("Telemetry event", %{
    telemetry_event: event,
    measurements: measurements,
    metadata: metadata,
    event_type: "telemetry"
  })
end
```

### Phase 4C: Error Tracking and Exception Handling

**Goal**: Comprehensive error tracking with OpenTelemetry span recording.

#### Step 4C.1: Create Error Handler Module
Create `lib/growth/error_handler.ex`:

```elixir
defmodule Growth.ErrorHandler do
  @moduledoc """
  Centralized error handling with OpenTelemetry integration.
  """

  require OpenTelemetry.Tracer
  alias Growth.StructuredLogger

  @doc """
  Handle and record errors in OpenTelemetry spans and structured logs.
  """
  def handle_error(error, context \\ %{}) do
    # Record exception in current span
    OpenTelemetry.Tracer.record_exception(error, context)
    OpenTelemetry.Tracer.set_status(:error, Exception.message(error))

    # Log with full context
    StructuredLogger.error("Application error occurred", %{
      "error.type" => error.__struct__ |> to_string(),
      "error.message" => Exception.message(error),
      "error.context" => context,
      "error.stacktrace" => Exception.format_stacktrace(__STACKTRACE__)
    })

    # Emit telemetry event
    :telemetry.execute([:growth, :error, :occurred], %{count: 1}, %{
      error_type: error.__struct__,
      error_message: Exception.message(error),
      context: context
    })
  end

  @doc """
  Wrap functions with error handling.
  """
  def with_error_handling(context, fun) do
    try do
      fun.()
    rescue
      error ->
        handle_error(error, context)
        reraise error, __STACKTRACE__
    end
  end
end
```

## REVISED Implementation Timeline

### Week 1: Enhanced Telemetry Bridge (Phase 3A)
- [x] Add OpenTelemetry bridge setup to existing `lib/growth_web/telemetry.ex`
- [x] Enhance existing telemetry events with OpenTelemetry-compatible attributes
- [x] Test span creation and attribute propagation with existing infrastructure
- [x] Verify bridge integration with current telemetry metrics

### Week 2: Additive Span Enhancement (Phase 3B)
- [x] Add span events to existing `Growth.Calculate` telemetry spans
- [x] Create new OpenTelemetry instrumentation for `Growth.Classify`, `Growth.Zscore`, `Growth.Percentile`
- [x] Implement error tracking with span status in existing error paths
- [x] Test complementary instrumentation without disrupting current telemetry

### Week 3: PromEx Custom Metrics Integration (Phase 4A)
- [x] Create `Growth.PromExPlugin` with custom metrics aligned to existing events
- [x] Update existing `Growth.PromEx.plugins/0` to include custom plugin
- [x] Test metrics collection and Prometheus endpoint integration
- [x] Verify custom metrics complement existing telemetry metrics

### Week 4: Enhanced JSON Logging (Phase 4B & 4C)
- [x] Configure `logger_json` integration with OpenTelemetry trace correlation
- [x] Implement `Growth.StructuredLogger` working with existing `logger_json`
- [x] Update existing telemetry `handle_event/4` to use structured logging
- [x] Enhance error paths in business logic with structured logging
- [x] Test trace correlation and JSON log format integration

## REVISED Validation Checklist

**✅ OpenTelemetry Bridge Integration:**
- [ ] Existing telemetry spans appear as OpenTelemetry spans in observability tools
- [ ] Bridge preserves all current telemetry functionality
- [ ] Enhanced span attributes include business context (child.gender, calculation.data_type, etc.)
- [ ] Trace correlation works across existing and new spans
- [ ] Error spans recorded with proper OpenTelemetry status

**✅ Enhanced Metrics:**
- [ ] Custom PromEx plugin integrates with existing `Growth.PromEx` setup
- [ ] Growth-specific metrics appear in `/metrics` endpoint alongside existing ones
- [ ] Business metrics (calculation duration, success rates) correlate with traces
- [ ] Performance metrics capture calculation latencies by data type
- [ ] Metrics complement existing telemetry without duplication

**✅ Structured JSON Logging:**
- [ ] `logger_json` configuration includes OpenTelemetry trace correlation
- [ ] Structured logs include trace_id and span_id for correlation
- [ ] Business logic logs use appropriate levels (info, debug, error)
- [ ] Error logs include full context and maintain existing error handling
- [ ] Logs correlate with spans in observability tools (trace_id matching)

**✅ Integration Compatibility:**
- [ ] All existing telemetry events continue working unchanged
- [ ] Current telemetry metrics in `GrowthWeb.Telemetry.metrics/0` remain functional
- [ ] Existing `Growth.PromEx` setup enhanced without breaking changes
- [ ] `logger_json` integration preserves current JSON log format
- [ ] No disruption to current development/logging workflows

**✅ Performance & Reliability:**
- [ ] Minimal latency increase (<5%) due to additive approach
- [ ] Memory usage stable (no significant overhead from bridges)
- [ ] CPU impact minimal (leveraging existing spans)
- [ ] Observability data export functioning to configured backends
- [ ] Graceful degradation if OpenTelemetry backend unavailable

**Key Success Factors:**
- **Enhancement over replacement**: All changes build on existing solid foundation
- **Backward compatibility**: No breaking changes to current telemetry/logging
- **Incremental rollout**: Each phase can be deployed and validated independently
- **Production safety**: Existing functionality preserved throughout implementation