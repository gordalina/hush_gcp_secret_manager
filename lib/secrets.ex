defmodule Hush.Provider.GcpSecretManager.Secrets do
  @moduledoc """
  This module provides a function fetch/3 to retrieve secrets from GCP.

  Example

      iex> Secrets.fetch(project_id, secret)
      {:ok, "value"}

      iex> Secrets.fetch(project_id, secret, "1")
      {:error, :not_found}
  """

  alias Goth.Token
  alias Hush.Provider.GcpSecretManager

  def fetch(project_id, secret, version \\ "latest") do
    with {:ok, token} <- token(),
         url <- url(project_id, secret, version),
         headers <- headers(token) do
      case http().get(url, headers) do
        {:ok, %{body: body, status_code: 200}} ->
          %{"payload" => %{"data" => data}} = Jason.decode!(body)
          {:ok, Base.decode64!(data)}

        {:ok, %{status_code: 404}} ->
          {:error, :not_found}

        {:ok, %{body: body}} ->
          {:error, body}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp headers(token) do
    [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"},
      {"accept", "application/json"}
    ]
  end

  @base_url "https://secretmanager.googleapis.com/v1/"
  defp url(project_id, secret, version) do
    @base_url <> "projects/#{project_id}/secrets/#{secret}/versions/#{version}:access"
  end

  # https://developers.google.com/identity/protocols/oauth2/scopes#secretmanager
  @oauth_scope "https://www.googleapis.com/auth/cloud-platform"
  defp token() do
    with {:ok, %Token{token: token}} <- goth_token().for_scope(@oauth_scope) do
      {:ok, token}
    end
  end

  defp http() do
    Application.get_env(:hush_gcp_secret_manager, :http, GcpSecretManager.Http)
  end

  defp goth_token() do
    Application.get_env(:hush_gcp_secret_manager, :goth, GcpSecretManager.Goth)
  end
end
