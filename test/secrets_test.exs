defmodule Hush.Provider.GcpSecretManager.SecretTest do
  use ExUnit.Case, async: true
  import Mox
  doctest Hush.Provider.GcpSecretManager.Secret

  alias Goth.Token
  alias Hush.Provider.GcpSecretManager

  @project "hush"
  @token {:ok, %Token{token: "token"}}
  @headers [
    {"content-type", "application/json"},
    {"authorization", "Bearer token"},
    {"accept", "application/json"}
  ]

  describe "fetch/2" do
    test "success" do
      expect(GcpSecretManager.MockGoth, :for_scope, 4, fn scope ->
        assert scope == "https://www.googleapis.com/auth/cloud-platform"
        @token
      end)

      GcpSecretManager.MockHttp
      |> expect(:get, fn url, headers ->
        assert url ==
                 "https://secretmanager.googleapis.com/v1/projects/#{@project}/secrets/KEY_BASE/versions/latest:access"

        assert headers == @headers
        {:ok, %{body: response_body("secret"), status_code: 200}}
      end)

      assert {:ok, "secret"} == GcpSecretManager.Secret.fetch(@project, "KEY_BASE")
    end

    test "not found" do
      GcpSecretManager.MockGoth
      |> expect(:for_scope, 4, fn _ -> @token end)

      GcpSecretManager.MockHttp
      |> expect(:get, fn _, _ -> {:ok, %{status_code: 404}} end)

      assert {:error, :not_found} == GcpSecretManager.Secret.fetch(@project, "KEY_BASE")
    end

    test "project does not exist" do
      GcpSecretManager.MockGoth
      |> expect(:for_scope, 4, fn _ -> @token end)

      GcpSecretManager.MockHttp
      |> expect(:get, fn (_, _) ->
        {:ok, %{body: response_error("Permission denied on resource project")}}
      end)

      error = """
      The supplied account doesn't seem to have access to project
      'hush', ensure that it is:

        1) spelled correctly
        2) you have the right account key (json file)
        3) the account has enough permissions

      The original error message was: Permission denied on resource project
      """
      assert {:error, error} == GcpSecretManager.Secret.fetch(@project, "KEY")
    end

    test "not enough permission" do
      GcpSecretManager.MockGoth
      |> expect(:for_scope, 4, fn _ -> @token end)

      GcpSecretManager.MockHttp
      |> expect(:get, fn (_, _) ->
        {:ok, %{body: response_error("Permission VIEWER denied for resource")}}
      end)

      error = """
      The supplied account doesn't seem to have enough permissions to read secrets on project 'hush'.
      Ensure that this account has the 'Secret Manager Secret Accessor' (roles/secretmanager.secretAccessor) IAM role attached to it.

      The original error message was: Permission VIEWER denied for resource
      """
      assert {:error, error} == GcpSecretManager.Secret.fetch(@project, "KEY")
    end

    test "general error" do
      GcpSecretManager.MockGoth
      |> expect(:for_scope, 4, fn _ -> @token end)

      GcpSecretManager.MockHttp
      |> expect(:get, fn (_, _) ->
        {:ok, %{body: response_error("error")}}
      end)

      error = %{"error" => %{"message" => "error"}}
      assert {:error, error} == GcpSecretManager.Secret.fetch(@project, "KEY")
    end

    test "json error" do
      GcpSecretManager.MockGoth
      |> expect(:for_scope, 4, fn _ -> @token end)

      GcpSecretManager.MockHttp
      |> expect(:get, fn (_, _) ->
        {:ok, %{body: "this is not json"}}
      end)

      error = %Jason.DecodeError{
        data: "this is not json",
        position: 0
      }

      assert {:error, error} == GcpSecretManager.Secret.fetch(@project, "KEY")
    end
  end

  defp response_body(value) do
    Jason.encode!(%{"payload" => %{"data" => Base.encode64(value)}})
  end

  defp response_error(message) do
    Jason.encode!(%{"error" => %{"message" => message}})
  end
end
