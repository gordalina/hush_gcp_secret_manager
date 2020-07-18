defmodule Hush.Provider.GcpSecretManager.Goth do
  @moduledoc false
  @behaviour Hush.Provider.GcpSecretManager.GothBehaviour
  @impl true

  def for_scope(role) do
    Goth.Token.for_scope(role)
  end
end
