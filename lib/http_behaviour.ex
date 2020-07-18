defmodule Hush.Provider.GcpSecretManager.HttpBehaviour do
  @moduledoc false
  @callback get(String.t(), list(any())) :: {:ok, map()} | {:error, map()}
end
