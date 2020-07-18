defmodule Hush.Provider.GcpSecretManager.GothBehaviour do
  @moduledoc false
  @callback for_scope(String.t()) :: {:ok, map()} | {:error, map()} | :error
end
