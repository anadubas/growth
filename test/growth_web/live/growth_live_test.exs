defmodule GrowthWeb.GrowthLiveTest do
  @moduledoc false
  use GrowthWeb.LiveCase, async: false

  describe "validate_child" do
    test "re-renders form without advancing to measure step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#child-form", child: valid_child_attrs())
      |> render_change()

      assert has_element?(view, "#child-form")
      refute has_element?(view, "#measure-form")
    end
  end

  describe "validate_measure" do
    test "re-renders form without advancing to results step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      advance_to_measure_step(view)

      view
      |> form("#measure-form", measure: valid_measure_attrs())
      |> render_change()

      assert has_element?(view, "#measure-form")
      refute has_element?(view, "#chart-height")
    end
  end

  describe "save_child" do
    test "happy: advances to measure step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#child-form", child: valid_child_attrs())
      |> render_submit()

      assert has_element?(view, "#measure-form")
      refute has_element?(view, "#child-form")
    end

    test "zoi-invalid: stays on child step when name is too short", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#child-form", child: invalid_child_attrs())
      |> render_submit()

      assert has_element?(view, "#child-form")
      refute has_element?(view, "#measure-form")
    end
  end

  describe "save_measure" do
    test "happy: advances to results step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      advance_to_measure_step(view)

      view
      |> form("#measure-form", measure: valid_measure_attrs())
      |> render_submit()

      assert has_element?(view, "#chart-height")
      assert has_element?(view, "#chart-weight")
      assert has_element?(view, "#chart-bmi")
      assert has_element?(view, "#chart-hc")
      refute has_element?(view, "#measure-form")
    end

    test "zoi-invalid: stays on measure step when height is negative", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      advance_to_measure_step(view)

      view
      |> form("#measure-form", measure: invalid_measure_attrs())
      |> render_submit()

      assert has_element?(view, "#measure-form")
      refute has_element?(view, "#chart-height")
    end
  end

  describe "reset" do
    test "returns to child step from results", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      advance_to_results_step(view)

      view |> element("#reset-btn") |> render_click()

      assert has_element?(view, "#child-form")
      refute has_element?(view, "#measure-form")
      refute has_element?(view, "#chart-height")
    end
  end

  defp advance_to_measure_step(view) do
    view
    |> form("#child-form", child: valid_child_attrs())
    |> render_submit()
  end

  defp advance_to_results_step(view) do
    advance_to_measure_step(view)

    view
    |> form("#measure-form", measure: valid_measure_attrs())
    |> render_submit()
  end

  defp valid_child_attrs do
    %{
      "name" => "Jane Doe",
      "gender" => "female",
      "birthday" => Date.add(Date.utc_today(), -365 * 2)
    }
  end

  defp invalid_child_attrs do
    %{"name" => "An", "gender" => "female", "birthday" => Date.add(Date.utc_today(), -365 * 2)}
  end

  defp valid_measure_attrs do
    %{"height" => "80", "weight" => "12", "head_circumference" => "45"}
  end

  defp invalid_measure_attrs do
    %{"height" => "-5", "weight" => "12", "head_circumference" => "45"}
  end
end
