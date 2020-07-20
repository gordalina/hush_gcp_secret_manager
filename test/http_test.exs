defmodule Hush.Provider.GcpSecretManager.HttpTest do
  use ExUnit.Case
  doctest Hush.Provider.GcpSecretManager.Http
  alias Hush.Provider.GcpSecretManager

  test "for_scope/1" do
    assert_raise CaseClauseError, fn -> GcpSecretManager.Http.get("", []) end
  end
end
