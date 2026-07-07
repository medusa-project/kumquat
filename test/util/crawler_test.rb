require 'test_helper'

class CrawlerTest < ActiveSupport::TestCase 

  test 'user_agents returns non empty array based on crawlers.yml content' do 
    
    crawlers = Crawlers.user_agents
    assert_instance_of Array, crawlers
    assert_not_empty crawlers

  end

  test 'matches? returns false if user agent is blank' do 
    #todo
  end

  test 'matches? returns true if user agent matches any crawler element' do 
    #todo
  end

end