require 'test_helper'

class ConfigurationTest < ActiveSupport::TestCase

  def setup
    raw_config_struct = File.read(File.join(Rails.root, 'config', 'kumquat.yml'))
    @config_struct = YAML.load(ERB.new(raw_config_struct).result)[Rails.env]
    @config = Configuration.instance
  end

  # get()

  test 'get() with a bogus config key should return nil' do
    assert_nil @config.get(:bogus)
  end

  test 'get() with a valid config key should return the value' do
    assert_equal @config_struct[:iiif_url], @config.get(:iiif_url)
  end

  # method_missing()

  test 'method_missing() with a bogus config key should return nil' do
    assert_nil @config.bogus
  end

  test 'method_missing() with a valid config key should return the value' do
    assert_equal @config_struct[:iiif_url], @config.iiif_url
  end

end
