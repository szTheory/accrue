defmodule AccrueHost.AccrueCase do
  @moduledoc """
  Shared Accrue integration test support for the host app.

  Use this in tests that need the host Repo sandbox plus the public
  `Accrue.Test` helpers for fake processor, mail, PDF, and event assertions.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias AccrueHost.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import AccrueHost.AccrueCase

      use Accrue.Test
    end
  end

  setup tags do
    AccrueHost.DataCase.setup_sandbox(tags)

    :ok
  end
end
