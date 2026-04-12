defmodule AccrueTest do
  use ExUnit.Case, async: true

  test "Accrue namespace module is loaded" do
    assert Code.ensure_loaded(Accrue) == {:module, Accrue}
  end
end
