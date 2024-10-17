defmodule Growth do
  @moduledoc """
  Growth keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Growth.Calculate

  @type t :: %__MODULE__{
          name: String.t(),
          gender: String.t(),
          birthday: Date.t(),
          measure_date: Date.t(),
          height: number(),
          weight: number(),
          head_circumference: number(),
          bmi: number(),
          results: map()
        }

  @enforce_keys [:name, :gender, :birthday]

  defstruct [
    :name,
    :gender,
    :birthday,
    :measure_date,
    :age_in_months,
    :weight,
    :height,
    :head_circumference,
    :bmi,
    results: %{}
  ]

  @doc """
  Create a measure result for a child
  """
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) do
    attrs
    |> create_struct()
    |> add_age_in_months()
    |> add_bmi()
    |> add_results()
  end

  defp create_struct(attrs) do
    %__MODULE__{
      name: attrs.name,
      birthday: attrs.birthday,
      gender: attrs.gender,
      measure_date: Date.utc_today(),
      height: attrs.height,
      weight: attrs.weight,
      head_circumference: attrs.head_circumference
    }
  end

  defp add_age_in_months(%__MODULE__{birthday: birthday, measure_date: measure_date} = growth)
       when not is_nil(birthday) and not is_nil(measure_date) do
    {:ok, %{growth | age_in_months: Calculate.age_in_months(birthday, measure_date)}}
  end

  defp add_age_in_months(_growth), do: {:error, "no date"}

  defp add_bmi({:ok, %__MODULE__{weight: weight, height: height} = growth})
    when is_number(weight) and is_number(height) do
    {:ok, %{growth | bmi: Calculate.bmi(weight, height)}}
  end

  defp add_bmi({:ok, _growth}), do: {:error, "no measures"}
  defp add_bmi({:error, error}), do: {:error, error}

  defp add_results({:ok, growth}) do
    {:ok, %{growth | results: Calculate.results(growth)}}
  end

  defp add_results({:error, error}), do: {:error, error}
end
