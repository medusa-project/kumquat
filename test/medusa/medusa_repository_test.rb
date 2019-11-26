require 'test_helper'

class MedusaRepositoryTest < ActiveSupport::TestCase

  def setup
    @repo = medusa_repositories(:one)
  end

  # with_medusa_database_id()

  test 'with_medusa_database_id() should return an instance when given a UUID' do
    file = MedusaRepository.with_medusa_database_id(@repo.medusa_database_id)
    assert_equal @repo.title, file.title
  end

  test 'with_medusa_database_id() should cache returned instances' do
    MedusaRepository.destroy_all
    assert_nil MedusaRepository.find_by_medusa_database_id(@repo.medusa_database_id)
    MedusaRepository.with_medusa_database_id(@repo.medusa_database_id)
    assert_not_nil MedusaRepository.find_by_medusa_database_id(@repo.medusa_database_id)
  end

  # url()

  test 'url() should return the URL' do
    assert_equal Configuration.instance.medusa_url + '/repositories/' + @repo.medusa_database_id.to_s,
                 @repo.url
  end

end
