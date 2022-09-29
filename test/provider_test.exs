defmodule Hush.Provider.GcpSecretManagerTest do
  use ExUnit.Case, async: false
  import Mock

  doctest Hush.Provider.GcpSecretManager

  alias Goth.Token
  alias Hush.Provider.GcpSecretManager

  @token {:ok, %Token{token: "token"}}

  describe "load/1" do
    test "fails without a project id" do
      msg = """
      Configuration not set, please set the project id you'd like to
      read secrets from.

      The goth configuration is the same as you would configure goth itself. See https://github.com/peburrows/goth for more information.

      Example configuration:

        config :hush_gcp_secret_manager,
          goth: [name: MyApp.GothHush],
          project_id: "<gcp_project_id>"
      """

      Application.put_env(:hush_gcp_secret_manager, :project_id, nil)
      Application.put_env(:hush_gcp_secret_manager, :goth, name: Hush.GothMock)
      assert {:error, msg} == GcpSecretManager.load(nil)
      Application.put_env(:hush_gcp_secret_manager, :goth, nil)
    end

    test "fails without goth config" do
      msg = """
      Configuration not set, please set the project id you'd like to
      read secrets from.

      The goth configuration is the same as you would configure goth itself. See https://github.com/peburrows/goth for more information.

      Example configuration:

        config :hush_gcp_secret_manager,
          goth: [name: MyApp.GothHush],
          project_id: "<gcp_project_id>"
      """

      Application.put_env(:hush_gcp_secret_manager, :project_id, "project")
      Application.put_env(:hush_gcp_secret_manager, :goth, nil)
      assert {:error, msg} == GcpSecretManager.load(nil)
      Application.put_env(:hush_gcp_secret_manager, :project_id, nil)
      Application.put_env(:hush_gcp_secret_manager, :goth, nil)
    end

    test "ok with a project id" do
      Application.put_env(:hush_gcp_secret_manager, :project_id, "project_id")
      Application.put_env(:hush_gcp_secret_manager, :goth, name: Hush.GothMockOk)

      children = [
        {Finch, name: Hush.Provider.GcpSecretManager.Finch},
        {Goth, name: Hush.GothMockOk}
      ]

      assert {:ok, children} == GcpSecretManager.load(nil)

      Application.put_env(:hush_gcp_secret_manager, :project_id, nil)
      Application.put_env(:hush_gcp_secret_manager, :goth, nil)
    end

    test "with config" do
      Application.put_env(:hush_gcp_secret_manager, :project_id, nil)
      Application.put_env(:hush_gcp_secret_manager, :goth, nil)

      children = [
        {Finch, name: Hush.Provider.GcpSecretManager.Finch},
        {Goth, name: Hush.GothMockOk}
      ]

      config = [
        {:hush_gcp_secret_manager, [project_id: "project_id", goth: [name: Hush.GothMockOk]]}
      ]

      assert {:ok, children} == GcpSecretManager.load(config)
    end
  end

  describe "fetch/1" do
    setup do
      Application.put_env(:hush_gcp_secret_manager, :project_id, "hush")
      Application.put_env(:hush_gcp_secret_manager, :goth, name: Hush.GothMock)

      on_exit(fn ->
        Application.put_env(:hush_gcp_secret_manager, :project_id, nil)
        Application.put_env(:hush_gcp_secret_manager, :goth, nil)
      end)
    end

    test_with_mock("decode body", %{}, Goth, [], fetch: fn _ -> @token end) do
      with_mock Finch,
        build: fn _, _, _ -> %{} end,
        request: fn _, _ -> response_ok("secret") end do
        assert {:ok, "secret"} == GcpSecretManager.fetch("key")
      end
    end

    test_with_mock("correct url", %{}, Goth, [], fetch: fn _ -> @token end) do
      with_mock Finch,
        build: fn method, url, _ ->
          assert method == :get

          assert url ==
                   "https://secretmanager.googleapis.com/v1/projects/hush/secrets/secret_name/versions/latest:access"

          %{}
        end,
        request: fn _, _ -> response_ok("secret_name") end do
        GcpSecretManager.fetch("secret_name")
      end
    end

    test_with_mock("goth token", %{}, Goth, [], fetch: fn _ -> @token end) do
      with_mock Finch,
        build: fn _, _, headers ->
          assert Enum.member?(headers, {"authorization", "Bearer token"})
        end,
        request: fn _, _ -> response_error("not_found") end do
        GcpSecretManager.fetch("not_found")
      end
    end

    test_with_mock("not_found", %{}, Goth, [], fetch: fn _ -> @token end) do
      with_mock Finch,
        build: fn _, _, _ -> nil end,
        request: fn _, _ -> {:ok, %{status: 404}} end do
        assert {:error, :not_found} == GcpSecretManager.fetch("not_found")
      end
    end

    test_with_mock("project does not exist", %{}, Goth, [], fetch: fn _ -> @token end) do
      with_mock Finch,
        build: fn _, _, _ -> nil end,
        request: fn _, _ -> response_error("Permission denied on resource project") end do
        error = """
        The supplied account doesn't seem to have access to project
        'hush', ensure that it is:

          1) spelled correctly
          2) you have the right account key (json file)
          3) the account has enough permissions

        The original error message was: Permission denied on resource project
        """

        assert {:error, error} == GcpSecretManager.fetch("KEY")
      end
    end

    test_with_mock("invalid json", %{}, Goth, [], fetch: fn _ -> @token end) do
      with_mock Finch,
        build: fn _, _, _ -> nil end,
        request: fn _, _ -> {:ok, %{status: 200, body: "internal server error"}} end do
        result = GcpSecretManager.fetch("KEY")
        assert {:error, _} = result

        {:error, message} = result
        assert message =~ "Could not parse json '\"internal server error\"': %Jason.DecodeError{"
      end
    end

    test_with_mock("invalid json in error", %{}, Goth, [], fetch: fn _ -> @token end) do
      with_mock Finch,
        build: fn _, _, _ -> nil end,
        request: fn _, _ -> {:ok, %{status: 500, body: "internal server error"}} end do
        result = GcpSecretManager.fetch("KEY")
        assert {:error, _} = result

        {:error, message} = result
        assert message =~ "Could not parse json '\"internal server error\"': %Jason.DecodeError{"
      end
    end

    test_with_mock("not enough permissions", %{}, Goth, [], fetch: fn _ -> @token end) do
      with_mock Finch,
        build: fn _, _, _ -> nil end,
        request: fn _, _ -> response_error("Permission VIEWER denied for resource") end do
        error = """
        The supplied account doesn't seem to have enough permissions to read secrets on project 'hush'.
        Ensure that this account has the 'Secret Manager Secret Accessor' (roles/secretmanager.secretAccessor) IAM role attached to it.

        The original error message was: Permission VIEWER denied for resource
        """

        assert {:error, error} == GcpSecretManager.fetch("KEY")
      end
    end

    test_with_mock("finch exception", %{}, Goth, [], fetch: fn _ -> @token end) do
      with_mock Finch,
        build: fn _, _, _ -> nil end,
        request: fn _, _ -> {:error, "error"} end do
        assert {:error, "\"error\""} == GcpSecretManager.fetch("KEY")
      end
    end

    test_with_mock("goth exception", %{}, Goth, [], fetch: fn _ -> {:error, "error"} end) do
      assert {:error, "error"} == GcpSecretManager.fetch("KEY")
    end

    test_with_mock("goth undefined exception", %{}, Goth, [], fetch: fn _ -> {:err, "error"} end) do
      assert {:error, "{:err, \"error\"}"} == GcpSecretManager.fetch("KEY")
    end
  end

  defp response_ok(value) do
    {:ok,
     %{
       status: 200,
       body: Jason.encode!(%{"payload" => %{"data" => Base.encode64(value)}})
     }}
  end

  defp response_error(message) do
    {:ok, %{body: Jason.encode!(%{"error" => %{"message" => message}})}}
  end
end
