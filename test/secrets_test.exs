defmodule Hush.Provider.GcpSecretManager.SecretsTest do
  use ExUnit.Case, async: true
  import Mox
  doctest Hush.Provider.GcpSecretManager.Goth

  alias Goth.Token
  alias Hush.Provider.GcpSecretManager

  @project "hush"
  @token {:ok, %Token{token: "token"}}
  @headers [
    {"content-type", "application/json"},
    {"authorization", "Bearer token"},
    {"accept", "application/json"}
  ]

  defp response_body(value) do
    Jason.encode!(%{"payload" => %{"data" => Base.encode64(value)}})
  end

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

      assert {:ok, "secret"} == GcpSecretManager.Secrets.fetch(@project, "KEY_BASE")
    end

    test "not found" do
      GcpSecretManager.MockGoth
      |> expect(:for_scope, 4, fn _ -> @token end)

      GcpSecretManager.MockHttp
      |> expect(:get, fn _, _ -> {:ok, %{status_code: 404}} end)

      assert {:error, :not_found} == GcpSecretManager.Secrets.fetch(@project, "KEY_BASE")
    end
  end
end
