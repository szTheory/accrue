ExUnit.start()

defmodule AccrueAdmin.SubscriptionCompositionsManifestBootTest do
  use ExUnit.Case, async: false

  test "compiled collection composition manifest is available" do
    assert Code.ensure_loaded?(AccrueAdmin.Storybook.SubscriptionCompositionsManifest),
           "the compiled collection composition manifest is unavailable"
  end
end
