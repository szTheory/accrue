defmodule AccrueHostWeb.PageControllerTest do
  use AccrueHostWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ "CohortFlow"
    assert html =~ "Three realistic billing roles"
    assert html =~ ~p"/pricing"
    assert html =~ ~p"/billing"
    assert html =~ "/app/billing"
    assert html =~ ~p"/admin"
    assert html =~ "accrue-demo-password"
    assert html =~ "healthy@example.com"
    assert html =~ "Northstar Academy"
    assert html =~ "Developer routes"
    refute html =~ "Accrue demo"
    refute html =~ "Example host"
    refute html =~ "Fake processor"
  end

  test "GET /pricing", %{conn: conn} do
    conn = get(conn, ~p"/pricing")
    html = html_response(conn, 200)

    assert html =~ "CohortFlow pricing"
    assert html =~ "Plans for cohort programs"
    assert html =~ "Launch"
    assert html =~ "Studio"
    assert html =~ "Scale"
    assert html =~ "price_basic"
    assert html =~ "price_pro"
    assert html =~ "price_metered"
    assert html =~ "$15"
    assert html =~ "$30"
    assert html =~ "Usage based"
    refute html =~ "Fake processor"
    refute html =~ "Public preview"
  end
end
