defmodule Hush.Provider.GcpSecretManager do
  @moduledoc """
  Implements a Hush.Provider behaviour to resolve secrets from
  Google Secret Manager at runtime.

  To configure this provider, hush and hush_gcp_secret_manager.

  The configuration supplied to :hush_gcp_secret_manager.goth is in the same format as
  you would configure goth, as per https://github.com/peburrows/goth

      # config.exs

      config :hush,
        providers: [Hush.Provider.GcpSecretManager]

      config :hush_gcp_secret_manager,
        goth: [name: MyApp.GothHush, source: ...],
        project_id: "my_project_id"
  """

  alias Goth.Token
  alias Hush.Provider.GcpSecretManager.Finch, as: FinchClient

  @behaviour Hush.Provider

  @impl Hush.Provider
  @spec load(config :: any()) :: :ok | {:error, any()}
  def load(config) do
    config = [
      project_id: config(:project_id, config),
      goth: config(:goth, config)
    ]

    with {:ok, _} <- Application.ensure_all_started(:goth),
         :ok <- config |> validate(),
         :ok <- Application.put_all_env([{:hush_gcp_secret_manager, config}]) do
      children = [
        {Finch, name: FinchClient},
        {Goth, Keyword.get(config, :goth)}
      ]

      {:ok, children}
    end
  end

  @impl Hush.Provider
  @spec fetch(key :: String.t()) ::
          {:ok, String.t()} | {:error, :not_found} | {:error, String.t()}
  def fetch(key) do
    project_id = config(:project_id)
    timeout = config(:goth_timeout) || 5_000
    goth = config(:goth)
    url = url(project_id, key, "latest")

    with {:ok, %Token{token: token}} <- Goth.fetch(goth[:name], timeout) do
      :get
      |> Finch.build(url, headers(token))
      |> Finch.request(FinchClient)
      |> case do
        {:ok, %{body: body, status: 200}} ->
          success(body)

        {:ok, %{status: 404}} ->
          {:error, :not_found}

        {:ok, %{body: body}} ->
          parse_response_error(body, project_id)

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    else
      {:error, error} -> {:error, error}
      error -> {:error, inspect(error)}
    end
  end

  defp headers(token) do
    [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"},
      {"accept", "application/json"}
    ]
  end

  defp success(body) do
    case parse_json(body) do
      {:ok, %{"payload" => %{"data" => data}}} ->
        {:ok, Base.decode64!(data)}

      error ->
        error
    end
  end

  defp parse_response_error(body, project_id) do
    case parse_json(body) do
      {:ok, %{"error" => %{"message" => message}}} ->
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
            The supplied account doesn't seem to have enough permissions to read secrets on project '#{project_id}'.
            Ensure that this account has the 'Secret Manager Secret Accessor' (roles/secretmanager.secretAccessor) IAM role attached to it.

            The original error message was: #{message}
            """

            {:error, msg}

          true ->
            {:error, body}
        end

      error ->
        error
    end
  end

  defp parse_json(body) do
    case Jason.decode(body) do
      {:ok, result} ->
        {:ok, result}

      {:error, error} ->
        {:error, "Could not parse json '#{inspect(body)}': #{inspect(error)}"}
    end
  end

  defp config(key, config \\ nil) do
    if config == nil do
      Application.get_env(:hush_gcp_secret_manager, key)
    else
      config[:hush_gcp_secret_manager][key]
    end
  end

  @base_url "https://secretmanager.googleapis.com/v1/"
  defp url(project_id, secret, version) do
    @base_url <> "projects/#{project_id}/secrets/#{secret}/versions/#{version}:access"
  end

  defp validate(config) do
    project_id = Keyword.get(config, :project_id, :not_a_binary)
    goth = Keyword.get(config, :goth, :not_a_keyword)

    if is_binary(project_id) and Keyword.keyword?(goth) do
      :ok
    else
      message = """
      Configuration not set, please set the project id you'd like to
      read secrets from.

      The goth configuration is the same as you would configure goth itself. See https://github.com/peburrows/goth for more information.

      Example configuration:

        config :hush_gcp_secret_manager,
          goth: [name: MyApp.GothHush],
          project_id: "<gcp_project_id>"
      """

      {:error, message}
    end
  end
end
