import Config

config :goth, json: ~S({
  "project_id": "project_id",
  "private_key": "key",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/app.iam.gserviceaccount.com"
})

if Mix.env() == :test, do: import_config("test.exs")
