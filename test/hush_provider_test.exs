defmodule Hush.Provider.GcpSecretManagerTest do
  use ExUnit.Case, async: true
  import Mox
  doctest Hush.Provider.GcpSecretManager
  alias Hush.Provider.GcpSecretManager

  describe "load/1" do
    test "fails without a project id" do
      msg = """
      Configuration not set, please set the project id you'd like to
      read secrets from. Example configuration:

        config :hush_gcp_secret_manager,
          project_id: "<gcp_project_id>"
      """

      assert {:error, msg} == GcpSecretManager.load(nil)
    end

    test "ok with a project id" do
      Application.put_env(:hush_gcp_secret_manager, :project_id, "project_id")
      assert :ok == GcpSecretManager.load(nil)
      Application.put_env(:hush_gcp_secret_manager, :project_id, nil)
    end

    test "with config" do
      assert nil == Application.get_env(:hush_gcp_secret_manager, :project_id)
      assert :ok == GcpSecretManager.load([{:hush_gcp_secret_manager, [project_id: "project_id"]}])
    end
  end

  describe "fetch/1" do
    test "error" do
      expect(GcpSecretManager.MockGoth, :for_scope, 4, fn _ ->
        {:error, "failed"}
      end)

      assert {:error, "failed"} == GcpSecretManager.fetch("KEY_BASE")
    end
  end
end
