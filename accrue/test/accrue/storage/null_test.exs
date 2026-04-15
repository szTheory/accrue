defmodule Accrue.Storage.NullTest do
  use ExUnit.Case, async: false

  alias Accrue.Storage

  setup do
    prev = Application.get_env(:accrue, :storage_adapter)
    Application.delete_env(:accrue, :storage_adapter)

    on_exit(fn ->
      if prev do
        Application.put_env(:accrue, :storage_adapter, prev)
      else
        Application.delete_env(:accrue, :storage_adapter)
      end
    end)

    :ok
  end

  describe "impl/0 default" do
    test "returns Accrue.Storage.Null when :storage_adapter unset" do
      assert Storage.impl() == Accrue.Storage.Null
    end
  end

  describe "Null adapter via facade" do
    test "put/3 echoes key untouched" do
      assert {:ok, "invoices/inv_123.pdf"} =
               Storage.put("invoices/inv_123.pdf", <<1, 2, 3>>, %{content_type: "application/pdf"})
    end

    test "put/3 defaults meta to empty map" do
      assert {:ok, "k"} = Storage.put("k", <<0>>)
    end

    test "get/1 returns :not_configured" do
      assert {:error, :not_configured} = Storage.get("invoices/inv_123.pdf")
    end

    test "delete/1 returns :not_configured" do
      assert {:error, :not_configured} = Storage.delete("invoices/inv_123.pdf")
    end
  end

  describe "telemetry spans" do
    setup do
      test_pid = self()
      ref = make_ref()
      handler_id = {__MODULE__, ref}

      events = [
        [:accrue, :storage, :put, :start],
        [:accrue, :storage, :put, :stop],
        [:accrue, :storage, :get, :start],
        [:accrue, :storage, :get, :stop],
        [:accrue, :storage, :delete, :start],
        [:accrue, :storage, :delete, :stop]
      ]

      :telemetry.attach_many(
        handler_id,
        events,
        fn name, measurements, metadata, _ ->
          send(test_pid, {:telemetry_event, name, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      :ok
    end

    test "put/3 emits :accrue, :storage, :put span with adapter + key + bytes metadata" do
      Storage.put("invoices/a.pdf", <<1, 2, 3, 4>>, %{})

      assert_received {:telemetry_event, [:accrue, :storage, :put, :start], _m, meta_start}
      assert meta_start.adapter == Accrue.Storage.Null
      assert meta_start.key == "invoices/a.pdf"
      assert meta_start.bytes == 4

      assert_received {:telemetry_event, [:accrue, :storage, :put, :stop], _m, _meta}
    end

    test "get/1 emits :accrue, :storage, :get span" do
      Storage.get("invoices/a.pdf")

      assert_received {:telemetry_event, [:accrue, :storage, :get, :start], _m, meta}
      assert meta.adapter == Accrue.Storage.Null
      assert meta.key == "invoices/a.pdf"
      assert_received {:telemetry_event, [:accrue, :storage, :get, :stop], _m, _}
    end

    test "delete/1 emits :accrue, :storage, :delete span" do
      Storage.delete("invoices/a.pdf")

      assert_received {:telemetry_event, [:accrue, :storage, :delete, :start], _m, meta}
      assert meta.adapter == Accrue.Storage.Null
      assert meta.key == "invoices/a.pdf"
      assert_received {:telemetry_event, [:accrue, :storage, :delete, :stop], _m, _}
    end

    test "put span metadata does not contain raw binary payload" do
      Storage.put("k", <<7, 8, 9>>, %{})

      assert_received {:telemetry_event, [:accrue, :storage, :put, :start], _m, meta}
      refute Map.has_key?(meta, :binary)
      refute Map.has_key?(meta, :body)
      assert meta.bytes == 3
    end
  end
end
