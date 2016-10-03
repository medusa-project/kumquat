require 'test_helper'

class ConfigurationTest < ActiveSupport::TestCase

  def setup
    @config_struct = YAML.load_file(File.join(Rails.root, 'config', 'peartree.yml'))[Rails.env]
    @config = Configuration.instance
  end

  # get()

  test 'get() with a bogus config key should return nil' do
    assert_nil @config.get(:bogus)
  end

  test 'get() with a valid config key should return the value' do
    assert_equal @config_struct[:repository_pathname],
                 @config.get(:repository_pathname)
  end

  # method_missing()

  test 'method_missing() with a bogus config key should return nil' do
    assert_nil @config.bogus
  end

  test 'method_missing() with a valid config key should return the value' do
    assert_equal @config_struct[:repository_pathname], @config.repository_pathname
  end

end
