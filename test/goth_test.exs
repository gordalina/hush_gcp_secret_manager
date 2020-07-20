defmodule Hush.Provider.GcpSecretManager.GothTest do
  use ExUnit.Case
  doctest Hush.Provider.GcpSecretManager.Goth
  alias Hush.Provider.GcpSecretManager

  test "for_scope/1" do
    assert_raise MatchError, fn -> GcpSecretManager.Goth.for_scope("scope") end
  end
end
