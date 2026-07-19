defmodule Growth.Child do
  @moduledoc """
  Represents a child whose growth metrics are evaluated against WHO growth standards.

  This module defines the `Growth.Child` struct, which holds core demographic data required
  for growth assessments, such as the child's name, gender, and birth date.

  It also includes helper functions to construct a child struct.

  ## Fields

  * `:name` - The child's full name (optional for calculations, required for UI display).
  * `:gender` - Gender as a string (`"male"` or `"female"`).
  * `:birthday` - The child's birth date (`Date.t()`).

  ## Example

      iex> {:ok, child} = Growth.Child.new(%{name: "Alice", gender: "female", birthday: ~D[2022-01-15]})
  """

  @schema Zoi.struct(
            __MODULE__,
            %{
              name: Zoi.string() |> Zoi.required(),
              gender: Zoi.enum(["male", "female"]) |> Zoi.required(),
              birthday: Zoi.date() |> Zoi.required()
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)

  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Create child
  """
  @spec new(map()) :: {:ok, t()} | {:error, [Zoi.Error.t()]}
  def new(attrs) do
    case Zoi.parse(schema(), attrs) do
      {:ok, child} ->
        :telemetry.execute([:growth, :child, :created], %{count: 1}, %{gender: child.gender})

        {:ok, child}

      error ->
        error
    end
  end

  @spec schema :: Zoi.schema()
  def schema do
    @schema
  end
end
