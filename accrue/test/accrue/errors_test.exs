defmodule Accrue.ErrorsTest do
  use ExUnit.Case, async: true

  @errors [
    Accrue.APIError,
    Accrue.CardError,
    Accrue.RateLimitError,
    Accrue.IdempotencyError,
    Accrue.DecodeError,
    Accrue.SignatureError,
    Accrue.ConfigError
  ]

  describe "all error structs" do
    for mod <- @errors do
      test "#{inspect(mod)} is an Exception" do
        # Force the module to load before introspection; in parallel test
        # runs it may not yet be in the code server.
        Code.ensure_loaded!(unquote(mod))
        assert function_exported?(unquote(mod), :exception, 1)
        assert function_exported?(unquote(mod), :message, 1)
        err = unquote(mod).exception(message: "hi")
        assert is_exception(err)
      end
    end
  end

  describe "Accrue.APIError" do
    test "carries rich fields" do
      err =
        Accrue.APIError.exception(
          message: "500",
          code: "api_error",
          http_status: 500,
          request_id: "req_1",
          processor_error: %{raw: true}
        )

      assert err.code == "api_error"
      assert err.http_status == 500
      assert err.request_id == "req_1"
    end

    test "rescue+pattern-match" do
      try do
        raise Accrue.APIError, code: "oops", message: "x"
      rescue
        e in Accrue.APIError -> assert e.code == "oops"
      end
    end
  end

  describe "Accrue.CardError" do
    test "message/1 derives from code/decline_code when :message is nil" do
      err =
        Accrue.CardError.exception(code: "card_declined", decline_code: "generic", param: "number")

      assert Exception.message(err) =~ "card_declined"
      assert Exception.message(err) =~ "generic"
      assert Exception.message(err) =~ "number"
    end

    test "processor_error field is settable but documented as sensitive" do
      err = Accrue.CardError.exception(code: "x", processor_error: %{secret: 1})
      assert err.processor_error == %{secret: 1}
      # message/1 must NOT leak processor_error contents (T-FND-05 mitigation)
      refute Exception.message(err) =~ "secret"
    end
  end

  describe "Accrue.RateLimitError" do
    test "derives message from retry_after" do
      err = Accrue.RateLimitError.exception(retry_after: 5)
      assert Exception.message(err) =~ "5s"
    end
  end

  describe "Accrue.IdempotencyError" do
    test "carries key" do
      err = Accrue.IdempotencyError.exception(idempotency_key: "abc-123")
      assert err.idempotency_key == "abc-123"
      assert Exception.message(err) =~ "abc-123"
    end
  end

  describe "Accrue.DecodeError" do
    test "carries payload" do
      err = Accrue.DecodeError.exception(payload: "{invalid")
      assert err.payload == "{invalid"
    end
  end

  describe "Accrue.SignatureError (D-08)" do
    test "raises, never returns tuple" do
      assert_raise Accrue.SignatureError, fn ->
        raise Accrue.SignatureError, reason: "bad_mac"
      end
    end

    test "has no tuple-return constructor" do
      refute function_exported?(Accrue.SignatureError, :new, 1)
      refute function_exported?(Accrue.SignatureError, :error_tuple, 1)
    end

    test "message derives from reason" do
      err = Accrue.SignatureError.exception(reason: "timestamp_expired")
      assert Exception.message(err) =~ "timestamp_expired"
    end
  end

  describe "Accrue.ConfigError" do
    test "carries the key" do
      err = Accrue.ConfigError.exception(key: :stripe_secret_key)
      assert err.key == :stripe_secret_key
      assert Exception.message(err) =~ "stripe_secret_key"
    end
  end
end
