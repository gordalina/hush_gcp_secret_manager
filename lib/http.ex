defmodule Hush.Provider.GcpSecretManager.Http do
  @moduledoc false
  @behaviour Hush.Provider.GcpSecretManager.HttpBehaviour
  @impl true
  def get(url, headers) do
    HTTPoison.get(url, headers)
  end
end
