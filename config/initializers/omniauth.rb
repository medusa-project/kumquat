Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.production?
    opts = YAML.load_file(File.join(Rails.root, 'config', 'peartree.yml'))[Rails.env]
    provider :shibboleth, opts.
        select{ |k,v| k.to_s.start_with?('shibboleth_') }.
        map{ |k,v| { k.to_s.gsub('shibboleth_', '').to_sym => v } }
  else
    provider :developer
  end
end
OmniAuth.config.logger = Rails.logger
