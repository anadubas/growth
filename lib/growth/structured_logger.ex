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
  def log(level, message, metadata \ %{}) when level in [:debug, :info, :warn, :error] do
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
  def info(message, metadata \ %{}), do: log(:info, message, metadata)
  def warn(message, metadata \ %{}), do: log(:warn, message, metadata)
  def error(message, metadata \ %{}), do: log(:error, message, metadata)
  def debug(message, metadata \ %{}), do: log(:debug, message, metadata)

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
