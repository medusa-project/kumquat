# Configures the uiuc_lib_ad gem

require 'configuration'

app_config = ::Configuration.instance

UiucLibAd::Configuration.instance = UiucLibAd::Configuration.new(
  user:     app_config.ad_user,
  password: app_config.ad_password,
  server:   app_config.ad_server,
  treebase: app_config.ad_treebase
)
