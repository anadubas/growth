defmodule GrowthWeb.Form do
  @moduledoc """
  Schemas used to validate child and measure data.
  """

  alias GrowthWeb.Form.Child
  alias GrowthWeb.Form.Measure

  @spec child_schema() :: Zoi.schema()
  def child_schema, do: Child.schema()

  @spec measure_schema() :: Zoi.schema()
  def measure_schema, do: Measure.schema()

  @spec child_parse(map()) :: Zoi.Context.t()
  def child_parse(attrs), do: Zoi.Form.parse(child_schema(), attrs)

  @spec measure_parse(map()) :: Zoi.Context.t()
  def measure_parse(attrs), do: Zoi.Form.parse(measure_schema(), attrs)

  @spec child_form(map(), atom()) :: Phoenix.HTML.Form.t()
  @spec child_form(map(), atom(), keyword()) :: Phoenix.HTML.Form.t()
  def child_form(attrs, form_name, opts \\ []),
    do: attrs |> child_parse() |> Phoenix.Component.to_form(Keyword.put(opts, :as, form_name))

  @spec measure_form(map(), atom()) :: Phoenix.HTML.Form.t()
  @spec measure_form(map(), atom(), keyword()) :: Phoenix.HTML.Form.t()
  def measure_form(attrs, form_name, opts \\ []),
    do: attrs |> measure_parse() |> Phoenix.Component.to_form(Keyword.put(opts, :as, form_name))
end
