Airbrake.configure do |config|
  config.api_key = '5fb40fea468f35f4048f576c82fc5892'
  config.host    = 'pangi.shiriculapo.com'
  config.port    = 80
  config.secure  = config.port == 443
end
