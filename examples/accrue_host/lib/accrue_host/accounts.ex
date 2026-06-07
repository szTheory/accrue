defmodule AccrueHost.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias AccrueHost.Repo

  alias AccrueHost.Accounts.{Scope, User, UserNotifier, UserSession, UserToken}
  alias AccrueHost.Organizations

  @session_validity_in_days 14
  @magic_link_ttl_seconds 15 * 60

  def sigra_config(opts \\ []) do
    organizations_module =
      if Keyword.get(opts, :organizations, true) do
        Organizations
      end

    Sigra.Config.new!(
      repo: Repo,
      user_schema: User,
      scope_module: Scope,
      organizations_module: organizations_module,
      session: [
        store: Sigra.SessionStores.Ecto,
        session_schema: UserSession,
        remember_me_max_age: @session_validity_in_days * 24 * 60 * 60
      ],
      mfa: [enabled: false],
      passkeys: [enabled: false],
      oauth: [enabled: false],
      suspicious_login: [enabled: false],
      lockout: [notify: false]
    )
  end

  defp session_store_opts do
    [repo: Repo, session_schema: UserSession]
  end

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: Sigra.Email.normalize(email))
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    case Sigra.Auth.authenticate(sigra_config(), %{email: email, password: password}) do
      {:ok, user} -> user
      {:ok, user, _metadata} -> user
      {:error, _reason} -> nil
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    Sigra.Auth.register(Repo, attrs,
      changeset_fn: &User.email_changeset(%User{}, &1),
      scope_module: Scope
    )
    |> case do
      {:error, :email_taken} ->
        {:error,
         User.email_changeset(%User{}, attrs)
         |> Ecto.Changeset.add_error(:email, "has already been taken")}

      other ->
        other
    end
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `AccrueHost.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `AccrueHost.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    case Sigra.Account.set_password(Repo, user, attrs,
           changeset_fn: &User.password_changeset/2,
           config: sigra_config()
         ) do
      {:ok, user} ->
        expired_sessions = list_user_sessions(user.id)
        {_count, _} = Sigra.Auth.delete_all_sessions(sigra_config(), user.id)
        delete_all_legacy_tokens(user.id)
        {:ok, {user, expired_sessions}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user, opts \\ []) do
    select_active_organization? = Keyword.get(opts, :select_active_organization, true)

    metadata = %{
      type: Keyword.get(opts, :type, :standard),
      ip: Keyword.get(opts, :ip),
      user_agent: Keyword.get(opts, :user_agent),
      active_organization_id: Keyword.get(opts, :active_organization_id)
    }

    {:ok, session} =
      Sigra.Auth.create_session(
        sigra_config(organizations: select_active_organization?),
        user,
        metadata
      )

    session.token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    case get_user_and_session_by_token(token) do
      {user, session} -> {user, session.inserted_at}
      nil -> nil
    end
  end

  def get_user_and_session_by_token(token) when is_binary(token) do
    with {:ok, hashed_token} <- hash_session_token(token),
         {:ok, session} <- Sigra.SessionStores.Ecto.fetch(hashed_token, session_store_opts()),
         true <- valid_session?(session),
         %User{} = user <- Repo.get(User, session.user_id) do
      authenticated_at = session.sudo_at || DateTime.truncate(session.inserted_at, :second)
      {%{user | authenticated_at: authenticated_at}, session}
    else
      _ -> nil
    end
  end

  def get_user_and_session_by_token(_), do: nil

  defp hash_session_token(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} -> {:ok, Sigra.Token.hash_token(decoded_token)}
      :error -> :error
    end
  end

  defp valid_session?(%Sigra.Session{inserted_at: %DateTime{} = inserted_at}) do
    DateTime.after?(
      inserted_at,
      DateTime.utc_now() |> DateTime.add(-@session_validity_in_days, :day)
    )
  end

  defp valid_session?(_), do: false

  defp list_user_sessions(user_id) do
    Sigra.SessionStores.Ecto.list_by_user(user_id, session_store_opts())
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, hashed_token} <- hash_session_token(token),
         %UserToken{inserted_at: inserted_at, user_id: user_id} <-
           Repo.get_by(UserToken, token: hashed_token, context: "magic_link"),
         true <- magic_link_fresh?(inserted_at) do
      Repo.get(User, user_id)
    else
      _ -> nil
    end
  end

  defp magic_link_fresh?(%DateTime{} = inserted_at),
    do: DateTime.diff(DateTime.utc_now(), inserted_at, :second) <= @magic_link_ttl_seconds

  defp magic_link_fresh?(%NaiveDateTime{} = inserted_at),
    do: inserted_at |> DateTime.from_naive!("Etc/UTC") |> magic_link_fresh?()

  defp magic_link_fresh?(_), do: false

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    case Sigra.Auth.verify_magic_link(Repo, token,
           user_schema: User,
           user_token_schema: UserToken,
           magic_link_ttl: @magic_link_ttl_seconds,
           scope_module: Scope
         ) do
      {:ok, user} -> {:ok, {user, []}}
      {:error, _reason} -> {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {:ok, {_raw_token, url}} =
      Sigra.Auth.request_magic_link(Repo, user.email,
        user_schema: User,
        user_token_schema: UserToken,
        url_fun: magic_link_url_fun,
        scope_module: Scope
      )

    UserNotifier.deliver_login_instructions(user, url)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    with {:ok, hashed_token} <- hash_session_token(token) do
      Sigra.Auth.delete_session(sigra_config(), hashed_token)
    end

    :ok
  end

  defp delete_all_legacy_tokens(user_id) do
    Repo.delete_all(from(t in UserToken, where: t.user_id == ^user_id))
  end
end
