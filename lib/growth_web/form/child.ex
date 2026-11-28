defmodule GrowthWeb.Form.Child do
  @moduledoc """
  Form schema to validate child data information.
  """

  @schema Zoi.map(
            %{
              name: Zoi.string() |> Zoi.min(3) |> Zoi.max(512),
              gender: Zoi.enum(["male", "female"]),
              birthday: Zoi.date() |> Zoi.coerce()
            },
            coerce: true
          )

  @spec form(map() | Zoi.Context.t()) :: Phoenix.HTML.Form.t()
  @spec form(map() | Zoi.Context.t(), atom()) :: Phoenix.HTML.Form.t()
  @spec form(map() | Zoi.Context.t(), atom(), keyword()) :: Phoenix.HTML.Form.t()
  def form(attrs, form_name \\ :child, opts \\ [])

  def form(%Zoi.Context{} = attrs, form_name, opts) do
    Phoenix.Component.to_form(attrs, Keyword.put(opts, :as, form_name))
  end

  def form(attrs, form_name, opts) do
    attrs
    |> parse()
    |> form(form_name, opts)
  end

  @spec parse(map()) :: Zoi.Context.t()
  def parse(attrs), do: Zoi.Form.parse(schema(), attrs)

  @spec schema :: Zoi.schema()
  def schema, do: @schema
end
