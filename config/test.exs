import Config

alias Hush.Provider.GcpSecretManager

config :hush_gcp_secret_manager,
  http: GcpSecretManager.MockHttp,
  goth: GcpSecretManager.MockGoth
