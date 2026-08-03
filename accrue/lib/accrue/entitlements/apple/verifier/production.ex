defmodule Accrue.Entitlements.Apple.Verifier.Production do
  @moduledoc false
  @behaviour Accrue.Entitlements.Apple.Verifier

  alias Accrue.Entitlements.Apple.Verifier
  alias Verifier.Config

  @p256_order 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551
  @allowed_header_keys MapSet.new(["alg", "x5c", "typ"])
  @apple_leaf_purpose {1, 2, 840, 113_635, 100, 6, 11, 1}
  @apple_intermediate_purpose {1, 2, 840, 113_635, 100, 6, 2, 1}
  @claim_keys ~w(bundleId environment appAppleId originalTransactionId transactionId productId appAccountToken signedDate expiresDate notificationUUID)

  @impl true
  def verify_notification(jws, %Config{} = config) when is_binary(jws) do
    with {:ok, payload} <- authenticate(jws, config),
         {:ok, data} <- notification_data(payload),
         :ok <- validate_claims(data, config),
         {:ok, transaction_jws} <- nested(data, "signedTransactionInfo"),
         {:ok, renewal_jws} <- nested(data, "signedRenewalInfo"),
         {:ok, transaction} <- verify(transaction_jws, config),
         {:ok, renewal} <- verify(renewal_jws, config) do
      {:ok,
       %{notification: facts(payload), transaction: facts(transaction), renewal: facts(renewal)}}
    end
  end

  def verify_notification(_, _), do: {:error, :invalid_payload}

  @impl true
  def verify_transaction(jws, %Config{} = config) when is_binary(jws),
    do: verify(jws, config) |> facts_result()

  def verify_transaction(_, _), do: {:error, :invalid_payload}

  @impl true
  def verify_renewal(jws, %Config{} = config) when is_binary(jws),
    do: verify(jws, config) |> facts_result()

  def verify_renewal(_, _), do: {:error, :invalid_payload}

  defp facts_result({:ok, payload}), do: {:ok, facts(payload)}
  defp facts_result(error), do: error

  defp verify(jws, %Config{} = config) do
    with {:ok, payload} <- authenticate(jws, config),
         :ok <- validate_claims(payload, config) do
      {:ok, payload}
    end
  end

  defp authenticate(jws, %Config{} = config) do
    with {:ok, protected64, payload64, signature64} <- split(jws),
         {:ok, header} <- decode_json(protected64),
         :ok <- validate_header(header),
         {:ok, payload} <- decode_json(payload64),
         {:ok, verification_time} <- resolve_verification_time(payload, config),
         :ok <- validate_chain(header["x5c"], config, verification_time),
         {:ok, leaf_key} <- leaf_key(header["x5c"]),
         :ok <- verify_signature(protected64 <> "." <> payload64, signature64, leaf_key) do
      {:ok, payload}
    end
  rescue
    ArgumentError -> {:error, :invalid_payload}
    _ -> {:error, :invalid_chain}
  end

  defp split(jws) do
    case String.split(jws, ".", trim: false) do
      [protected64, payload64, signature64]
      when byte_size(protected64) > 0 and byte_size(payload64) > 0 and byte_size(signature64) > 0 ->
        {:ok, protected64, payload64, signature64}

      _ ->
        {:error, :invalid_payload}
    end
  end

  defp decode_json(segment) do
    with {:ok, bytes} <- Base.url_decode64(segment, padding: false),
         {:ok, value} when is_map(value) <- Jason.decode(bytes) do
      {:ok, value}
    else
      _ -> {:error, :invalid_payload}
    end
  end

  defp validate_header(header) do
    keys = header |> Map.keys() |> MapSet.new()

    cond do
      not MapSet.subset?(keys, @allowed_header_keys) ->
        {:error, :invalid_header}

      Map.has_key?(header, "crit") ->
        {:error, :invalid_header}

      header["alg"] != "ES256" ->
        {:error, :invalid_algorithm}

      not is_list(header["x5c"]) or header["x5c"] == [] ->
        {:error, :invalid_header}

      not Enum.all?(header["x5c"], &(is_binary(&1) and byte_size(&1) > 0)) ->
        {:error, :invalid_header}

      true ->
        :ok
    end
  end

  # `x5c` is leaf-first. The configured root is pinned, never taken from the JWS.
  defp validate_chain(x5c, %Config{roots: roots}, verification_time)
       when is_list(roots) and roots != [] do
    with {:ok, ders} <- decode_chain(x5c),
         {:ok, certs} <- decode_certificates(ders),
         :ok <- validate_roots_and_path(roots, certs, verification_time),
         :ok <- validate_leaf_purpose(certs) do
      :ok
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :invalid_chain}
    end
  end

  defp validate_chain(_, _, _), do: {:error, :invalid_chain}

  defp decode_chain(x5c) do
    decoded = Enum.map(x5c, &Base.decode64/1)

    if Enum.all?(decoded, &match?({:ok, _}, &1)),
      do: {:ok, Enum.map(decoded, fn {:ok, der} -> der end)},
      else: {:error, :invalid_chain}
  end

  defp decode_certificates(ders) do
    certs = Enum.map(ders, &:public_key.pkix_decode_cert(&1, :otp))
    if length(certs) == length(ders), do: {:ok, certs}, else: {:error, :invalid_chain}
  rescue
    _ -> {:error, :invalid_chain}
  end

  defp configured_root(root) when is_binary(root) do
    {:ok, :public_key.pkix_decode_cert(root, :otp)}
  rescue
    _ -> {:error, :invalid_chain}
  end

  defp configured_root(root) when is_tuple(root), do: {:ok, root}
  defp configured_root(_), do: {:error, :invalid_chain}

  defp validate_roots_and_path(roots, certs, verification_time) do
    Enum.reduce_while(roots, {:error, :invalid_chain}, fn root, result ->
      case configured_root(root) do
        {:ok, decoded_root} ->
          case validate_order_and_path(decoded_root, certs, verification_time) do
            :ok ->
              {:halt, :ok}

            {:error, :invalid_certificate_time} ->
              {:cont, {:error, :invalid_certificate_time}}

            {:error, _} ->
              {:cont, result}
          end

        {:error, _} ->
          {:cont, {:error, :invalid_chain}}
      end
    end)
  end

  defp validate_order_and_path(root, certs, verification_time) do
    # OTP validates issuer/child order, basic constraints, keyCertSign, and
    # signatures. It has no policy-time option, so validate that policy first.
    with :ok <- validate_certificate_times([root | certs], verification_time) do
      case :public_key.pkix_path_validation(
             root,
             Enum.reverse(certs),
             verify_fun: {&verify_fun/3, :configured_time_checked}
           ) do
        {:ok, _} -> :ok
        _ -> {:error, :invalid_chain}
      end
    end
  rescue
    _ -> {:error, :invalid_chain}
  end

  # The explicit policy check is authoritative for time. Only OTP's redundant
  # host-clock expiry events may continue; every other PKIX event stays closed.
  defp verify_fun(_cert, {:bad_cert, reason}, state)
       when reason in [:cert_expired, :cert_not_yet_valid],
       do: {:valid, state}

  defp verify_fun(_cert, :valid, state), do: {:valid, state}
  defp verify_fun(_cert, :valid_peer, state), do: {:valid_peer, state}
  defp verify_fun(_cert, {:extension, _extension}, state), do: {:unknown, state}
  defp verify_fun(_cert, event, _state), do: {:fail, event}

  defp validate_certificate_times(certs, verification_time) do
    if Enum.all?(certs, &certificate_valid_at?(&1, verification_time)),
      do: :ok,
      else: {:error, :invalid_certificate_time}
  end

  defp certificate_valid_at?(cert, verification_time) do
    with {:Validity, not_before, not_after} <- cert |> elem(1) |> elem(5),
         {:ok, not_before} <- certificate_time(not_before),
         {:ok, not_after} <- certificate_time(not_after) do
      DateTime.compare(verification_time, not_before) != :lt and
        DateTime.compare(verification_time, not_after) != :gt
    else
      _ -> false
    end
  end

  defp certificate_time({:utcTime, time}) do
    case to_string(time) do
      <<year::binary-size(2), month::binary-size(2), day::binary-size(2), hour::binary-size(2),
        minute::binary-size(2), second::binary-size(2), "Z">> ->
        year = String.to_integer(year)
        year = if year >= 50, do: 1900 + year, else: 2000 + year

        DateTime.new(
          Date.new!(year, String.to_integer(month), String.to_integer(day)),
          Time.new!(
            String.to_integer(hour),
            String.to_integer(minute),
            String.to_integer(second)
          ),
          "Etc/UTC"
        )

      _ ->
        {:error, :invalid_certificate_time}
    end
  rescue
    _ -> {:error, :invalid_certificate_time}
  end

  defp certificate_time({:generalTime, time}) do
    case to_string(time) do
      <<year::binary-size(4), month::binary-size(2), day::binary-size(2), hour::binary-size(2),
        minute::binary-size(2), second::binary-size(2), "Z">> ->
        DateTime.new(
          Date.new!(String.to_integer(year), String.to_integer(month), String.to_integer(day)),
          Time.new!(
            String.to_integer(hour),
            String.to_integer(minute),
            String.to_integer(second)
          ),
          "Etc/UTC"
        )

      _ ->
        {:error, :invalid_certificate_time}
    end
  rescue
    _ -> {:error, :invalid_certificate_time}
  end

  defp certificate_time(_), do: {:error, :invalid_certificate_time}

  defp resolve_verification_time(_payload, %Config{verification_time: nil}),
    do: {:ok, DateTime.utc_now()}

  defp resolve_verification_time(_payload, %Config{verification_time: :current}),
    do: {:ok, DateTime.utc_now()}

  defp resolve_verification_time(payload, %Config{verification_time: :signed_date}) do
    with value when is_integer(value) <- payload["signedDate"],
         {:ok, instant} <- DateTime.from_unix(value, :millisecond),
         :lt <- DateTime.compare(instant, DateTime.add(DateTime.utc_now(), 300, :second)) do
      {:ok, instant}
    else
      _ -> {:error, :invalid_certificate_time}
    end
  end

  defp resolve_verification_time(_payload, %Config{verification_time: %DateTime{} = instant}) do
    if instant.time_zone == "Etc/UTC" and instant.utc_offset == 0 and instant.std_offset == 0,
      do: {:ok, instant},
      else: {:error, :invalid_certificate_time}
  end

  defp resolve_verification_time(_, _), do: {:error, :invalid_certificate_time}

  defp validate_leaf_purpose([leaf, intermediate, _root]) do
    # Apple's server libraries require these exact private-purpose extensions in
    # addition to ordinary PKIX path validation.  Do this before using the leaf
    # key, so a valid EC certificate issued for another Apple purpose is closed.
    with {:ECPoint, _} <- subject_public_key(leaf),
         true <- extension?(leaf, @apple_leaf_purpose),
         true <- extension?(intermediate, @apple_intermediate_purpose),
         true <- non_ca_leaf?(leaf),
         true <- digital_signature?(leaf) do
      :ok
    else
      _ -> {:error, :invalid_certificate_purpose}
    end
  rescue
    _ -> {:error, :invalid_certificate_purpose}
  end

  defp validate_leaf_purpose(_), do: {:error, :invalid_certificate_purpose}

  defp extension?(cert, oid) do
    cert
    |> extensions()
    |> Enum.any?(fn
      {:Extension, ^oid, _, _} -> true
      _ -> false
    end)
  end

  defp non_ca_leaf?(cert) do
    case extension_value(cert, {2, 5, 29, 19}) do
      nil ->
        true

      {:BasicConstraints, false, _} ->
        true

      value ->
        match?({:BasicConstraints, false, _}, :public_key.der_decode(:BasicConstraints, value))
    end
  rescue
    _ -> false
  end

  defp digital_signature?(cert) do
    case extension_value(cert, {2, 5, 29, 15}) do
      nil ->
        false

      usages when is_list(usages) ->
        :digitalSignature in usages

      value ->
        case :public_key.der_decode(:KeyUsage, value) do
          <<1::1, _::bitstring>> -> true
          _ -> false
        end
    end
  rescue
    _ -> false
  end

  defp extension_value(cert, oid) do
    Enum.find_value(extensions(cert), fn
      {:Extension, ^oid, _, value} -> value
      _ -> nil
    end)
  end

  defp extensions(cert) do
    case cert |> elem(1) |> elem(10) do
      values when is_list(values) -> values
      _ -> []
    end
  end

  defp leaf_key(x5c) do
    with {:ok, [leaf | _]} <- decode_chain(x5c),
         cert <- :public_key.pkix_decode_cert(leaf, :otp),
         info <- subject_public_key_info(cert) do
      {:ok, {elem(info, 2), info |> elem(1) |> elem(2)}}
    else
      _ -> {:error, :invalid_chain}
    end
  rescue
    _ -> {:error, :invalid_chain}
  end

  defp verify_signature(message, signature64, key) do
    with {:ok, raw} <- Base.url_decode64(signature64, padding: false),
         {:ok, der} <- raw_es256_to_der(raw),
         true <- :public_key.verify(message, :sha256, der, key) do
      :ok
    else
      false -> {:error, :invalid_signature}
      _ -> {:error, :invalid_signature}
    end
  rescue
    _ -> {:error, :invalid_signature}
  end

  defp raw_es256_to_der(<<r::unsigned-big-integer-size(256), s::unsigned-big-integer-size(256)>>)
       when r > 0 and r < @p256_order and s > 0 and s < @p256_order do
    r = der_integer(r)
    s = der_integer(s)
    {:ok, <<0x30, byte_size(r) + byte_size(s), r::binary, s::binary>>}
  end

  defp raw_es256_to_der(_), do: {:error, :invalid_signature}

  defp der_integer(value) do
    bytes = :binary.encode_unsigned(value)
    bytes = if :binary.first(bytes) >= 0x80, do: <<0, bytes::binary>>, else: bytes
    <<0x02, byte_size(bytes), bytes::binary>>
  end

  defp validate_claims(payload, %Config{} = config) do
    with :ok <- equal(payload["bundleId"], config.bundle_id, :wrong_bundle),
         :ok <-
           equal(
             payload["environment"],
             apple_environment(config.environment),
             :wrong_environment
           ),
         :ok <- validate_app_id(payload, config) do
      :ok
    end
  end

  defp validate_app_id(payload, %Config{environment: :production, app_apple_id: app_id})
       when not is_nil(app_id),
       do: equal(payload["appAppleId"], app_id, :wrong_app)

  defp validate_app_id(_, %Config{environment: :production}), do: {:error, :wrong_app}
  defp validate_app_id(_, %Config{environment: :sandbox}), do: :ok
  defp validate_app_id(_, _), do: {:error, :wrong_environment}

  defp equal(value, value, _reason), do: :ok
  defp equal(_, _, reason), do: {:error, reason}
  defp apple_environment(:production), do: "Production"
  defp apple_environment(:sandbox), do: "Sandbox"
  defp apple_environment(_), do: ""

  defp notification_data(payload) do
    case payload["data"] do
      data when is_map(data) -> {:ok, data}
      _ -> {:error, :invalid_payload}
    end
  end

  defp nested(data, key) do
    case data[key] do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, :invalid_payload}
    end
  end

  defp facts(payload), do: Map.take(payload, @claim_keys)

  defp subject_public_key(cert), do: subject_public_key_info(cert) |> elem(2)
  defp subject_public_key_info(cert), do: cert |> elem(1) |> elem(7)
end
