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
  defdelegate measure_new, to: Measure, as: :new
  defdelegate measure_new(index), to: Measure, as: :new

  @doc """
  Parses a list of measure attribute maps into one `Zoi.Context` per row,
  preserving index order so per-row errors can be routed back to the right form.
  """
  @spec measures_parse([map()]) :: [Zoi.Context.t()]
  def measures_parse(list) when is_list(list), do: Enum.map(list, &measure_parse/1)

  @doc """
  Builds one indexed `Phoenix.HTML.Form` per row. The row name becomes
  `measure[\#{index}]` (see `GrowthWeb.Form.Measure.row_name/1`), so each field
  renders as `measure[0][height]`, `measure[1][height]`, …
  """
  @spec measures_forms([map() | Zoi.Context.t()], keyword()) :: [Phoenix.HTML.Form.t()]
  def measures_forms(list, opts \\ []) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.map(fn {attrs, index} -> measure_form(attrs, Measure.row_name(index), opts) end)
  end
end
