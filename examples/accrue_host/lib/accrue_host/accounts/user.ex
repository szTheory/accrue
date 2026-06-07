defmodule AccrueHost.Accounts.User do
  use Ecto.Schema
  use Accrue.Billable, billable_type: "User"
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :billing_admin, :boolean, default: false
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true
    field :failed_login_attempts, :integer, default: 0
    field :locked_at, :utc_datetime
    field :password_changed_at, :utc_datetime
    field :pending_email, :string
    field :deleted_at, :utc_datetime
    field :scheduled_deletion_at, :utc_datetime
    field :original_email, :string
    field :must_change_password, :boolean, default: false
    field :mfa_trust_epoch, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(attrs) do
    registration_changeset(%__MODULE__{}, attrs)
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> email_changeset(attrs, opts)
    |> password_changeset(attrs, opts)
  end

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> update_change(:email, &Sigra.Email.normalize/1)
    |> validate_email(opts)
  end

  def pending_email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:pending_email])
    |> update_change(:pending_email, fn
      nil -> nil
      email -> Sigra.Email.normalize(email)
    end)
    |> validate_length(:pending_email, max: 160)
    |> maybe_validate_pending_email(opts)
  end

  defp maybe_validate_pending_email(changeset, opts) do
    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:pending_email, AccrueHost.Repo)
      |> unique_constraint(:pending_email)
    else
      changeset
    end
  end

  def email_change_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :pending_email, :confirmed_at])
    |> update_change(:email, &Sigra.Email.normalize/1)
    |> validate_email(Keyword.put(opts, :validate_changed, false))
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, AccrueHost.Repo)
      |> unique_constraint(:email)
      |> maybe_validate_email_changed(opts)
    else
      changeset
    end
  end

  defp maybe_validate_email_changed(changeset, opts) do
    if Keyword.get(opts, :validate_changed, true) do
      validate_email_changed(changeset)
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> Sigra.PasswordPolicy.validate(min_length: 12, check_common: false)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Sigra.Crypto.hash_password(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%AccrueHost.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    case Sigra.Crypto.verify_with_upgrade(password, hashed_password) do
      {:ok, :valid} -> true
      {:ok, :valid, _new_hash} -> true
      {:error, :invalid} -> false
    end
  end

  def valid_password?(_, _) do
    Sigra.Crypto.no_user_verify()
  end
end
