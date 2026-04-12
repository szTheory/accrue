defmodule Accrue.Processor.StripeTest do
  use ExUnit.Case, async: true

  alias Accrue.Processor.Stripe.ErrorMapper

  describe "ErrorMapper.to_accrue_error/1 — LatticeStripe.Error shapes" do
    test "maps :card_error to %Accrue.CardError{} preserving code/decline_code/param + raw" do
      raw = %LatticeStripe.Error{
        type: :card_error,
        code: "card_declined",
        decline_code: "insufficient_funds",
        param: "card[number]",
        message: "Your card was declined.",
        status: 402,
        request_id: "req_abc",
        charge: "ch_123"
      }

      assert %Accrue.CardError{
               code: "card_declined",
               decline_code: "insufficient_funds",
               param: "card[number]",
               http_status: 402,
               request_id: "req_abc",
               processor_error: ^raw
             } = ErrorMapper.to_accrue_error(raw)
    end

    test "maps :rate_limit_error to %Accrue.RateLimitError{}" do
      raw = %LatticeStripe.Error{
        type: :rate_limit_error,
        message: "Too many requests",
        status: 429,
        request_id: "req_rate"
      }

      assert %Accrue.RateLimitError{
               http_status: 429,
               request_id: "req_rate",
               processor_error: ^raw
             } = ErrorMapper.to_accrue_error(raw)
    end

    test "maps :idempotency_error to %Accrue.IdempotencyError{}" do
      raw = %LatticeStripe.Error{
        type: :idempotency_error,
        message: "Keys mismatch",
        status: 400,
        request_id: "req_idem"
      }

      assert %Accrue.IdempotencyError{processor_error: ^raw} =
               ErrorMapper.to_accrue_error(raw)
    end

    test "maps :invalid_request_error to %Accrue.APIError{}" do
      raw = %LatticeStripe.Error{
        type: :invalid_request_error,
        code: "missing_param",
        message: "missing email",
        status: 400,
        request_id: "req_inv"
      }

      assert %Accrue.APIError{
               code: "missing_param",
               http_status: 400,
               request_id: "req_inv",
               processor_error: ^raw
             } = ErrorMapper.to_accrue_error(raw)
    end

    test "maps :authentication_error to %Accrue.APIError{}" do
      raw = %LatticeStripe.Error{
        type: :authentication_error,
        message: "Invalid API key",
        status: 401
      }

      assert %Accrue.APIError{http_status: 401, processor_error: ^raw} =
               ErrorMapper.to_accrue_error(raw)
    end

    test "maps :api_error to %Accrue.APIError{}" do
      raw = %LatticeStripe.Error{type: :api_error, message: "oops", status: 500}

      assert %Accrue.APIError{http_status: 500, processor_error: ^raw} =
               ErrorMapper.to_accrue_error(raw)
    end

    test "maps :connection_error to %Accrue.APIError{} with no http_status" do
      raw = %LatticeStripe.Error{type: :connection_error, message: "timeout", status: nil}

      assert %Accrue.APIError{http_status: nil, processor_error: ^raw} =
               ErrorMapper.to_accrue_error(raw)
    end
  end

  describe "ErrorMapper.to_accrue_error/1 — SignatureError RAISES" do
    test "raises Accrue.SignatureError on signature_verification_failed LatticeStripe.Error" do
      raw = %LatticeStripe.Error{
        type: :invalid_request_error,
        code: "signature_verification_failed",
        message: "bad sig"
      }

      assert_raise Accrue.SignatureError, fn ->
        ErrorMapper.to_accrue_error(raw)
      end
    end

    test "raises Accrue.SignatureError on the webhook signature_verification_error struct" do
      assert_raise Accrue.SignatureError, fn ->
        ErrorMapper.to_accrue_error(%LatticeStripe.Webhook.SignatureVerificationError{
          message: "no header"
        })
      end
    end
  end

  describe "ErrorMapper.to_accrue_error/1 — defensive fallback" do
    test "unknown term maps to APIError code: unknown with processor_error set" do
      raw = {:weird, :term}

      assert %Accrue.APIError{code: "unknown", processor_error: ^raw} =
               ErrorMapper.to_accrue_error(raw)
    end
  end

  describe "Accrue.Processor.Stripe behaviour conformance" do
    test "implements the Accrue.Processor behaviour" do
      callbacks = Accrue.Processor.Stripe.module_info(:attributes)[:behaviour] || []
      assert Accrue.Processor in callbacks
    end

    test "raises Accrue.ConfigError when :stripe_secret_key is unset" do
      prior = Application.get_env(:accrue, :stripe_secret_key)
      Application.delete_env(:accrue, :stripe_secret_key)

      try do
        assert_raise Accrue.ConfigError, ~r/stripe_secret_key/, fn ->
          Accrue.Processor.Stripe.create_customer(%{email: "a@b"}, [])
        end
      after
        if prior, do: Application.put_env(:accrue, :stripe_secret_key, prior)
      end
    end
  end

  describe "facade lockdown — lattice_stripe is isolated" do
    test "LatticeStripe module references only appear inside Accrue.Processor.Stripe.* files" do
      # Match the capitalized module name LatticeStripe (with word boundaries)
      # rather than the :lattice_stripe atom form — Plan 02's frozen
      # `lib/accrue/config.ex` contains the atom in a doc comment
      # ("pinned by the `:lattice_stripe` wrapper") which is a documentation
      # reference, not a code coupling. The facade invariant we actually care
      # about is "no module calls into LatticeStripe.*" — that is what this
      # regex enforces (D-07, T-PROC-02).
      files =
        Path.wildcard("lib/accrue/**/*.ex")
        |> Enum.filter(fn path ->
          File.read!(path) =~ ~r/\bLatticeStripe\b/
        end)
        |> Enum.sort()

      allowed =
        Enum.sort([
          "lib/accrue/processor/stripe.ex",
          "lib/accrue/processor/stripe/error_mapper.ex"
        ])

      assert files == allowed,
             "LatticeStripe may only be referenced inside Accrue.Processor.Stripe. " <>
               "Found in: #{inspect(files)}"
    end
  end
end
