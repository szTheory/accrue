defmodule Accrue.Entitlements.Apple.Verifier do
  @moduledoc false

  @closed_errors [
    :invalid_payload,
    :invalid_algorithm,
    :invalid_header,
    :invalid_chain,
    :invalid_certificate_purpose,
    :invalid_certificate_time,
    :invalid_signature,
    :wrong_bundle,
    :wrong_environment,
    :wrong_app,
    :unsupported_family
  ]

  defmodule Config do
    @moduledoc false
    @enforce_keys [:roots, :bundle_id, :environment, :verifier_version, :config_version]
    defstruct [:roots, :bundle_id, :environment, :app_apple_id, :verification_time, :verifier_version, :config_version]
    @type t :: %__MODULE__{}
  end

  @type error :: unquote(Enum.reduce(@closed_errors, fn error, acc -> {:|, [], [error, acc]} end))
  @type result :: {:ok, map()} | {:error, error()}

  @callback verify_notification(binary(), Config.t()) :: result()
  @callback verify_transaction(binary(), Config.t()) :: result()
  @callback verify_renewal(binary(), Config.t()) :: result()

  @spec errors() :: [atom()]
  def errors, do: @closed_errors
end
