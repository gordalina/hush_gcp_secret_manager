alias Hush.Provider.GcpSecretManager

ExUnit.start()

Mox.defmock(GcpSecretManager.MockHttp, for: GcpSecretManager.HttpBehaviour)
Mox.defmock(GcpSecretManager.MockGoth, for: GcpSecretManager.GothBehaviour)
