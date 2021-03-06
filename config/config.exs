# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :gn_exec, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:gn_exec, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :gn_exec,
  gn_server_url: "http://127.0.0.1:8880/gnexec/",
  jobs_path_prefix: "./test/data/input"
# TODO make gn_server url available at runtime not at compile time
# http://blog.plataformatec.com.br/2016/05/how-to-config-environment-variables-with-elixir-and-exrm/
