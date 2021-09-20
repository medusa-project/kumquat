require 'test_helper'

class ElasticsearchClientTest < ActiveSupport::TestCase

  setup do
    @instance   = ElasticsearchClient.instance
    @test_index = Configuration.instance.elasticsearch_index
    @instance.delete_index(@test_index) if @instance.index_exists?(@test_index)
  end

  teardown do
    @instance.delete_index(@test_index) rescue nil
  end

  # create_index()

  test "create_index() creates an index" do
    @instance.create_index(@test_index)
    assert @instance.index_exists?(@test_index)
  end

  # create_index_alias()

  test "create_index_alias() creates an index alias" do
    alias_name = "test1-alias"
    begin
      @instance.create_index(@test_index)
      @instance.create_index_alias(@test_index, alias_name)
      assert @instance.index_exists?(@test_index)
      assert @instance.index_exists?(alias_name)
    ensure
      if @instance.index_exists?(alias_name)
        @instance.delete_index_alias(@test_index, alias_name)
      end
    end
  end

  # delete_by_query()

  test "delete_by_query() works" do
    # TODO: write this
  end

  # delete_index()

  test "delete_index() deletes an index" do
    begin
      @instance.create_index(@test_index)
      assert @instance.index_exists?(@test_index)
    ensure
      @instance.delete_index(@test_index)
      assert !@instance.index_exists?(@test_index)
    end
  end

  test "delete_index() raises an error when deleting a nonexistent index" do
    assert_raises IOError do
      @instance.delete_index("bogus")
    end
  end

  # delete_task()

  test "delete_task() deletes a task" do
    # TODO: write this
  end

  test "delete_task() raises an error when deleting a nonexistent task" do
    # TODO: write this
  end

  # delete_index_alias()

  test "delete_index_alias() works" do
    alias_name = "test1-alias"

    @instance.create_index(@test_index)
    @instance.create_index_alias(@test_index, alias_name)
    assert @instance.index_exists?(@test_index)
    assert @instance.index_exists?(alias_name)

    @instance.delete_index_alias(@test_index, alias_name)
    assert @instance.index_exists?(@test_index)
    assert !@instance.index_exists?(alias_name)
  end

  # get_document()

  test "get_document() returns nil for a missing document" do
    begin
      @instance.create_index(@test_index)
      assert_nil @instance.get_document(@test_index, "bogus")
    ensure
      @instance.delete_index(@test_index) rescue nil
    end
  end

  test "get_document() returns an existing document" do
    @instance.create_index(@test_index)
    @instance.index_document(@test_index, "id1", {})
    assert_not_nil @instance.get_document(@test_index, "id1")
  end

  # get_task()

  test "get_task() returns nil for a missing task" do
    # TODO: write this
  end

  test "get_task() returns an existing task" do
    # TODO: write this
  end

  # index_document()

  test "index_document() indexes a document" do
    @instance.create_index(@test_index)
    assert_nil @instance.get_document(@test_index, "id1")

    @instance.index_document(@test_index, "id1", {})
    assert_not_nil @instance.get_document(@test_index, "id1")
  end

  # index_exists?()

  test "index_exists?() works" do
    @instance.create_index(@test_index)
    assert @instance.index_exists?(@test_index)

    @instance.delete_index(@test_index) rescue nil
    assert !@instance.index_exists?(@test_index)
  end

  # indexes()

  test "indexes() works" do
    @instance.create_index(@test_index)
    assert_not_empty @instance.indexes
  end

  # purge()

  test "purge() purges all documents" do
    skip # TODO: fix this
    @instance.create_index(@test_index)

    @instance.index_document(@test_index, "id1", {})
    @instance.index_document(@test_index, "id2", {})
    @instance.index_document(@test_index, "id3", {})
    assert_not_nil @instance.get_document(@test_index, "id1")
    assert_not_nil @instance.get_document(@test_index, "id2")
    assert_not_nil @instance.get_document(@test_index, "id3")

    @instance.purge
    @instance.refresh
    assert_nil @instance.get_document(@test_index, "id1")
    assert_nil @instance.get_document(@test_index, "id2")
    assert_nil @instance.get_document(@test_index, "id3")
  end

  # query()

  test "query() works" do
    # TODO: write this
  end

  # reindex()

  test "reindex() reindexes all documents" do
    # TODO: write this
  end

  # refresh()

  test "refresh() refreshes the cluster" do
    # This is kind of hard to test, so we simply assert that no errors are
    # raised.
    @instance.refresh
  end

end
