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

  @spec child_form(map() | Zoi.Context.t(), atom()) :: Phoenix.HTML.Form.t()
  @spec child_form(map() | Zoi.Context.t(), atom(), keyword()) :: Phoenix.HTML.Form.t()
  def child_form(attrs, form_name, opts \\ [])

  def child_form(%Zoi.Context{} = attrs, form_name, opts),
    do: Phoenix.Component.to_form(attrs, Keyword.put(opts, :as, form_name))

  def child_form(attrs, form_name, opts),
    do: attrs |> child_parse() |> child_form(form_name, opts)

  @spec measure_form(map() | Zoi.Context.t(), atom()) :: Phoenix.HTML.Form.t()
  @spec measure_form(map() | Zoi.Context.t(), atom(), keyword()) :: Phoenix.HTML.Form.t()
  def measure_form(attrs, form_name, opts \\ [])

  def measure_form(%Zoi.Context{} = attrs, form_name, opts),
    do: Phoenix.Component.to_form(attrs, Keyword.put(opts, :as, form_name))

  def measure_form(attrs, form_name, opts),
    do: attrs |> measure_parse() |> measure_form(form_name, opts)
end
