defmodule Growth.Child do
  @moduledoc """
  The child basic info struct
  """

  alias Growth.Calculate

  @type t :: %__MODULE__{
          name: String.t(),
          gender: String.t(),
          birthday: Date.t(),
          measure_date: Date.t(),
          age_in_months: number()
        }

  @enforce_keys [:name, :gender, :birthday]

  defstruct [
    :name,
    :gender,
    :birthday,
    :measure_date,
    :age_in_months
  ]

  @doc """
  Create child
  """
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) do
    attrs
    |> create_struct()
    |> add_measure_date()
    |> add_age_in_months()
  end

  defp create_struct(attrs) do
    %__MODULE__{
      name: attrs["name"],
      birthday: Date.from_iso8601!(attrs["birthday"]),
      gender: attrs["gender"]
    }
  end

  defp add_measure_date(child) do
    %{child | measure_date: Date.utc_today()}
  end

  defp add_age_in_months(%__MODULE__{birthday: birthday, measure_date: measure_date} = child)
       when not is_nil(birthday) and not is_nil(measure_date) do
    {:ok, %{child | age_in_months: Calculate.age_in_months(birthday, measure_date)}}
  end
end
