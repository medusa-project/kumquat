require 'test_helper'

class MedusaRepositoryTest < ActiveSupport::TestCase

  def setup
    @repo = medusa_repositories(:one)
  end

  # sync_all()

  test 'sync_all() updates repositories that exist in Medusa' do
    @repo.update!(title: 'Cats')
    MedusaRepository.sync_all
    @repo.reload
    assert_equal 'Map and Geography Library', @repo.title
  end

  test 'sync_all() deletes repositories that do not exist in Medusa' do
    MedusaRepository.create!(medusa_database_id: 9999999)
    MedusaRepository.sync_all
    assert_equal 1, MedusaRepository.count
  end

  # with_medusa_database_id()

  test 'with_medusa_database_id() returns an instance when given a UUID' do
    repo2 = MedusaRepository.with_medusa_database_id(@repo.medusa_database_id)
    assert_equal @repo.medusa_database_id, repo2.medusa_database_id
    assert_equal @repo.contact_email, repo2.contact_email
    assert_equal @repo.email, repo2.email
    assert_equal @repo.title, repo2.title
    assert_equal @repo.ldap_admin_domain, repo2.ldap_admin_domain
    assert_equal @repo.ldap_admin_group, repo2.ldap_admin_group
  end

  test 'with_medusa_database_id() caches returned instances' do
    MedusaRepository.destroy_all
    assert_nil MedusaRepository.find_by_medusa_database_id(@repo.medusa_database_id)
    MedusaRepository.with_medusa_database_id(@repo.medusa_database_id)
    assert_not_nil MedusaRepository.find_by_medusa_database_id(@repo.medusa_database_id)
  end

  # load_from_medusa()

  test 'load_from_medusa() loads existing repositories from Medusa' do
    @repo.load_from_medusa
  end

  test 'load_from_medusa() raises an error for repositories that do not exist in Medusa' do
    repo = MedusaRepository.new(medusa_database_id: 999999999)
    assert_raises MissingError do
      repo.load_from_medusa
    end
  end

  # url()

  test 'url() returns the URL' do
    assert_equal Configuration.instance.medusa_url + '/repositories/' +
                     @repo.medusa_database_id.to_s,
                 @repo.url
  end

end
