defmodule Growth.ErrorHandler do
  @moduledoc """
  Centralized error handling with OpenTelemetry integration.
  """

  require OpenTelemetry.Tracer
  alias Growth.StructuredLogger

  @doc """
  Handle and record errors in OpenTelemetry spans and structured logs.
  """
  def handle_error(error, context \ %{}) do
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
