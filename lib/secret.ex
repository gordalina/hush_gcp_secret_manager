defmodule Hush.Provider.GcpSecretManager.Secret do
  @moduledoc """
  This module provides a function fetch/2 and fetch/3 to retrieve secrets from GCP.
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
          parse_error(body, project_id)

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

  defp parse_error(body, project_id) do
    try do
      body = Jason.decode!(body)
      %{"error" => %{"message" => message}} = body

      cond do
        String.match?(message, ~r/Permission denied on resource project/) ->
          msg = """
          The supplied account doesn't seem to have access to project
          '#{project_id}', ensure that it is:

            1) spelled correctly
            2) you have the right account key (json file)
            3) the account has enough permissions

          The original error message was: #{message}
          """

          {:error, msg}

        String.match?(message, ~r/Permission .* denied for resource/) ->
          msg = """
          The supplied account doesn't seem to have enough permissions to read secrets on project '#{
            project_id
          }'.
          Ensure that this account has the 'Secret Manager Secret Accessor' (roles/secretmanager.secretAccessor) IAM role attached to it.

          The original error message was: #{message}
          """

          {:error, msg}

        true ->
          {:error, body}
      end
    rescue
      e -> {:error, e}
    end
  end
end
