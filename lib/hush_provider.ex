defmodule Hush.Provider.GcpSecretManager do
  @moduledoc """
  Implements a Hush.Provider behaviour to resolve secrets
  from Google Secret Manager.

  To configure this provider, ensure you configure goth, hush and
  hush_gcp_secret_manager:

      config :goth,
        json: "service-account-key.json" |> File.read!

      config :hush,
        providers: [Hush.Provider.GcpSecretManager]

      config :hush_gcp_secret_manager,
        project_id: "my_project_id"
  """

  alias Hush.Provider.GcpSecretManager

  @behaviour Hush.Provider

  @impl true
  @spec load(config :: any()) :: :ok | {:error, any()}
  def load(_) do
    with {:ok, _} <- project() |> validate(),
         {:ok, _} <- Application.ensure_all_started(:goth),
         {:ok, _} <- Application.ensure_all_started(:httpoison) do
      :ok
    end
  end

  @impl true
  @spec fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found} | {:error, any()}
  def fetch(key) do
    project() |> GcpSecretManager.Secrets.fetch(key)
  end

  defp project() do
    Application.get_env(:hush_gcp_secret_manager, :project_id, nil)
  end

  defp validate(project) when is_binary(project), do: {:ok, project}

  defp validate(_) do
    message = """
    Configuration not set, please set the project id you'd like to
    read secrets from. Example configuration:

      config :hush_gcp_secret_manager,
        project_id: "<gcp_project_id>"
    """

    {:error, message}
  end
end
