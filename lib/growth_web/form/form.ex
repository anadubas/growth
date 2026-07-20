defmodule GrowthWeb.Form do
  @moduledoc """
  Schemas used to validate child and measure data.
  """

  alias GrowthWeb.Form.Child
  alias GrowthWeb.Form.Measure

  defdelegate child_schema, to: Child, as: :schema
  defdelegate child_parse(attrs), to: Child, as: :parse
  defdelegate child_form(attrs), to: Child, as: :form
  defdelegate child_form(attrs, form_name), to: Child, as: :form
  defdelegate child_form(attrs, form_name, opts), to: Child, as: :form
  defdelegate measure_schema, to: Measure, as: :schema
  defdelegate measure_parse(attrs), to: Measure, as: :parse
  defdelegate measure_form(attrs), to: Measure, as: :form
  defdelegate measure_form(attrs, form_name), to: Measure, as: :form
  defdelegate measure_form(attrs, form_name, opts), to: Measure, as: :form
end
