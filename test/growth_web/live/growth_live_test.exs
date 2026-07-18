defmodule GrowthWeb.GrowthLiveTest do
  use GrowthWeb.LiveCase, async: false

  describe "mount" do
    test "renders child form with empty fields and correct event wiring on initial load", %{
      conn: conn
    } do
      {:ok, view, html} = live(conn, ~p"/")

      assert has_element?(view, "#child-form")
      refute has_element?(view, "#measure-form")
      refute has_element?(view, "#chart-height")
      refute has_element?(view, "#reset-btn")

      assert has_element?(
               view,
               ~s|#child-form[phx-change="validate_child"][phx-submit="save_child"]|
             )

      assert has_element?(view, ~s|#child-form input[name="child[name]"][type="text"]|)
      assert has_element?(view, ~s|#child-form input[name="child[birthday]"][type="date"]|)
      assert has_element?(view, ~s|#child-form select[name="child[gender]"]|)

      # Form is built from %{} at mount, so fields start empty despite default_child/0
      refute html =~ ~s|name="child[name]" value="|
    end
  end

  describe "validate_child" do
    test "re-renders form with submitted values without advancing to measure step", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#child-form", child: valid_child_attrs())
        |> render_change()

      assert has_element?(view, "#child-form")
      refute has_element?(view, "#measure-form")
      assert has_element?(view, ~s|#child-form input[name="child[name]"][value="Jane Doe"]|)
      expected_birthday = birthday_months_ago(24)
      assert html =~ ~s|value="#{expected_birthday}"|
    end
  end

  describe "validate_measure" do
    test "re-renders form with submitted values without advancing to results step", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/")
      advance_to_measure_step(view)

      html =
        view
        |> form("#measure-form", measure: valid_measure_attrs())
        |> render_change()

      assert has_element?(view, "#measure-form")
      refute has_element?(view, "#chart-height")

      assert html =~ ~s|value="80.3"|
      assert html =~ ~s|value="12.2"|
      assert html =~ ~s|value="45"|
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

      assert has_element?(
               view,
               ~s|#measure-form[phx-change="validate_measure"][phx-submit="save_measure"]|
             )
    end

    test "zoi-invalid: stays on child step and renders error when name is too short", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#child-form", child: invalid_child_attrs())
      |> render_submit()

      assert has_element?(view, "#child-form")
      refute has_element?(view, "#measure-form")

      assert has_element?(view, "#child-form p.text-error")
      assert render(view) =~ "too small: must have at least 3 character(s)"
    end

    test "zoi-invalid then valid: error clears and step advances", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> form("#child-form", child: invalid_child_attrs()) |> render_submit()
      assert has_element?(view, "#child-form p.text-error")

      view |> form("#child-form", child: valid_child_attrs()) |> render_submit()

      refute has_element?(view, "#child-form")
      refute has_element?(view, "#child-form p.text-error")
      assert has_element?(view, "#measure-form")
    end
  end

  describe "save_measure" do
    test "advances to results step with populated chart data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      advance_to_measure_step(view)

      html =
        view
        |> form("#measure-form", measure: valid_measure_attrs())
        |> render_submit()

      assert has_element?(view, "#chart-height")
      assert has_element?(view, "#chart-weight")
      assert has_element?(view, "#chart-bmi")
      assert has_element?(view, "#chart-hc")
      refute has_element?(view, "#measure-form")

      for id <- ~w(chart-height chart-weight chart-bmi chart-hc) do
        assert has_element?(view, ~s|##{id}[phx-hook="GrowthChart"][data-chart]|)
      end

      for id <- ~w(chart-height chart-weight chart-bmi chart-hc) do
        chart = decode_chart_data(view, id)

        assert is_list(chart["child"])
        assert length(chart["child"]) == 1
        assert %{"x" => _, "y" => _} = hd(chart["child"])

        for key <- ~w(labels sd0 sd1 sd2 sd3 sd1neg sd2neg sd3neg) do
          assert Map.has_key?(chart, key), "chart #{id} missing key #{inspect(key)}"
        end
      end

      # Every indicator is available for a 2-year-old, so no note is shown.
      refute html =~ "Indisponível"
    end

    test "stays on measure step and renders error when height is negative", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/")

      advance_to_measure_step(view)

      view
      |> form("#measure-form", measure: invalid_measure_attrs())
      |> render_submit()

      assert has_element?(view, "#measure-form")
      refute has_element?(view, "#chart-height")

      assert has_element?(view, "#measure-form p.text-error")
      assert render(view) =~ "too small: must be at least 0"
    end

    # NOTE: (jpd) these are age limits for the availability of WHO reference data
    for {age_limit, age, label, available, unavailable} <- [
          {60, 90, "head circumference unavailable", ~w(chart-height chart-weight chart-bmi),
           ~w(chart-hc)},
          {120, 150, "weight and head circumference unavailable", ~w(chart-height chart-bmi),
           ~w(chart-weight chart-hc)},
          {228, 240, "all indicators unavailable", [],
           ~w(chart-height chart-weight chart-bmi chart-hc)}
        ] do
      test "over #{age_limit} months renders with #{label}", %{conn: conn} do
        {:ok, view, _html} = live(conn, ~p"/")

        view
        |> form("#child-form", child: valid_child_attrs(unquote(age)))
        |> render_submit()

        html =
          view
          |> form("#measure-form", measure: valid_measure_attrs())
          |> render_submit()

        # Core regression: the results step is reached without raising. The reset
        # button is always present on the results page; individual charts may be
        # omitted when their reference data is out of range.
        assert has_element?(view, "#reset-btn")
        refute html =~ "BadMapError"

        for id <- unquote(available) do
          chart = decode_chart_data(view, id)
          assert chart["labels"] != [], "expected reference data for ##{id} but labels were empty"
        end

        for id <- unquote(unavailable) do
          refute has_element?(view, "##{id}"),
                 "expected ##{id} to be absent (no reference data) but it was rendered"
        end

        assert html =~ "Indisponível para a idade",
               "expected an unavailability note for out-of-range indicators"
      end
    end
  end

  describe "reset" do
    test "returns to child step from results with cleared state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      advance_to_results_step(view)

      html = view |> element("#reset-btn") |> render_click()

      assert has_element?(view, "#child-form")
      refute has_element?(view, "#measure-form")
      refute has_element?(view, "#chart-height")

      refute has_element?(view, ~s|#child-form input[value="Jane Doe"]|)
      refute html =~ "Jane Doe"
    end
  end

  defp advance_to_results_step(view) do
    advance_to_measure_step(view)

    view
    |> form("#measure-form", measure: valid_measure_attrs())
    |> render_submit()
  end

  defp advance_to_measure_step(view) do
    view
    |> form("#child-form", child: valid_child_attrs())
    |> render_submit()
  end

  # HEEx HTML-escapes JSON in attributes ("  -> &quot;), so we unescape before Jason.decode!
  defp decode_chart_data(view, canvas_id) do
    html = render(view)

    [raw] =
      Regex.run(
        ~r/id="#{canvas_id}"[^>]*data-chart="([^"]*)"/,
        html,
        capture: :all_but_first
      )

    raw
    |> String.replace("&quot;", "\"")
    |> String.replace("&amp;", "&")
    |> Jason.decode!()
  end

  defp valid_child_attrs(age_in_months \\ 24) do
    %{
      "name" => "Jane Doe",
      "gender" => "female",
      "birthday" => birthday_months_ago(age_in_months)
    }
  end

  defp invalid_child_attrs(age_in_months \\ 24) do
    %{
      "name" => "An",
      "gender" => "female",
      "birthday" => birthday_months_ago(age_in_months)
    }
  end

  # measure_date defaults to today, so age is derived from this birthday. A
  # small day buffer keeps floor'd age_in_months comfortably in its bucket.
  defp birthday_months_ago(months) do
    Date.utc_today()
    |> Date.add(-trunc(months * 30.4375 + 5))
    |> Date.to_iso8601()
  end

  defp valid_measure_attrs do
    %{"height" => "80.3", "weight" => "12.2", "head_circumference" => "45"}
  end

  defp invalid_measure_attrs do
    %{"height" => "-5", "weight" => "12", "head_circumference" => "45"}
  end
end
