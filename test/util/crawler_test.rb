require 'test_helper'
require 'mocha/minitest'

class CrawlerTest < ActiveSupport::TestCase 

  test 'user_agents returns non empty array based on crawlers.yml content' do 
    
    crawlers = Crawler.user_agents

    assert_instance_of Array, crawlers
    assert_not_empty crawlers
  end

  test 'empty file yields empty array' do

    Crawler.instance_variable_set(:@user_agents, nil)
    YAML.stubs(:load_file).returns(nil)
  
    assert_empty Crawler.user_agents
  ensure
    Crawler.instance_variable_set(:@user_agents, nil) # memoized nil value is cleared to avoid affecting other tests
  end

  test 'missing file raises Errno::ENOENT' do
    #todo
  end

  test 'matches? returns false if user agent is blank' do 
    ua = ''
    assert_equal false, Crawler.matches?(ua)
  end

  test 'matches? returns true if user agent matches any crawler element' do 
    ua = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
    assert_equal true, Crawler.matches?(ua)
  end

end