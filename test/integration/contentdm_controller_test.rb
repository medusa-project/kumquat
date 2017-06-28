require 'test_helper'

class ContentdmControllerTest < ActionDispatch::IntegrationTest

  setup do
    @item = items(:sanborn_obj1)
  end

  test 'gone' do
    get('/ui/cdm/bla/bla')
    assert_response :gone

    get('/utils/getthumbnail/collection/alias/id/2')
    assert_response :gone

    get('/projects/test')
    assert_response :gone
  end

  test 'v4 reference URLs with valid item' do
    get("/u?/#{@item.contentdm_alias},#{@item.contentdm_pointer}")
    assert_response :moved_permanently
    assert_redirected_to @item
  end

  test 'v4 reference URLs with nonexistent item' do
    get('/u?/bogus,10')
    assert_response :see_other
    assert_redirected_to root_url
  end

  test 'v6 reference URLs with valid item' do
    get("/cdm/ref/collection/#{@item.contentdm_alias}/#{@item.contentdm_pointer}")
    assert_response :moved_permanently
    assert_redirected_to @item

    get("/cdm/ref/collection/#{@item.contentdm_alias}/id/#{@item.contentdm_pointer}")
    assert_response :moved_permanently
    assert_redirected_to @item
  end

  test 'v6 reference URLs with nonexistent item' do
    get('/cdm/ref/collection/bogus/10')
    assert_response :see_other
    assert_redirected_to root_url

    get('/cdm/ref/collection/bogus/id/10')
    assert_response :see_other
    assert_redirected_to root_url
  end

  test 'v6 single-item URLs with valid item' do
    get("/cdm/singleitem/collection/#{@item.contentdm_alias}/id/#{@item.contentdm_pointer}")
    assert_response :moved_permanently
    assert_redirected_to @item

    get("/cdm/singleitem/collection/#{@item.contentdm_alias}/id/#{@item.contentdm_pointer}/rec/1")
    assert_response :moved_permanently
    assert_redirected_to @item
  end

  test 'v6 single-item URLs with nonexistent item' do
    get('/cdm/singleitem/collection/bogus/id/10')
    assert_response :see_other
    assert_redirected_to root_url

    get('/cdm/singleitem/collection/bogus/id/10/rec/1')
    assert_response :see_other
    assert_redirected_to root_url
  end

  test 'v4 single-item URLs with valid item' do
    get("/cdm4/item_viewer.php?CISOROOT=#{@item.contentdm_alias}&CISOPTR=#{@item.contentdm_pointer}")
    assert_response :moved_permanently
    assert_redirected_to @item
  end

  test 'v4 single-item URLs with nonexistent item' do
    get('/cdm4/item_viewer.php?CISOROOT=bogus&CISOPTR=10')
    assert_response :see_other
    assert_redirected_to root_url
  end

  test 'v6 compound object URLs with valid object' do
    get("/cdm/compoundobject/collection/#{@item.contentdm_alias}/id/#{@item.contentdm_pointer}")
    assert_response :moved_permanently
    assert_redirected_to @item

    get("/cdm/compoundobject/collection/#{@item.contentdm_alias}/id/#{@item.contentdm_pointer}/rec/3")
    assert_response :moved_permanently
    assert_redirected_to @item

    get("/cdm/compoundobject/collection/#{@item.contentdm_alias}/id/#{@item.contentdm_pointer}/show/#{@item.contentdm_pointer}/rec/3")
    assert_response :moved_permanently
    assert_redirected_to @item
  end

  test 'v6 compound object URLs with nonexistent object' do
    get('/cdm/compoundobject/collection/bogus/id/10')
    assert_response :see_other
    assert_redirected_to root_url

    get('/cdm/compoundobject/collection/bogus/id/10/rec/3')
    assert_response :see_other
    assert_redirected_to root_url

    get('/cdm/compoundobject/collection/bogus/id/10/show/10/rec/3')
    assert_response :see_other
    assert_redirected_to root_url
  end

  test 'v4 compound object URLs with valid object' do
    get("/cdm4/document.php?CISOROOT=#{@item.contentdm_alias}&CISOPTR=#{@item.contentdm_pointer}")
    assert_response :moved_permanently
    assert_redirected_to @item
  end

  test 'v4 compound object URLs with nonexistent object' do
    get('/cdm4/document.php?CISOROOT=bogus&CISOPTR=10')
    assert_response :see_other
    assert_redirected_to root_url
  end

  test 'v6 collection pages with valid collection' do
    get("/cdm/landingpage/collection/#{@item.contentdm_alias}")
    assert_response :moved_permanently
    assert_redirected_to @item.collection

    get("/cdm/about/collection/#{@item.contentdm_alias}")
    assert_response :moved_permanently
    assert_redirected_to @item.collection
  end

  test 'v6 collection pages with nonexistent collection' do
    get('/cdm/landingpage/collection/bogus')
    assert_response :see_other
    assert_redirected_to collections_url

    get('/cdm/about/collection/bogus')
    assert_response :see_other
    assert_redirected_to collections_url
  end

  test 'v4 collection pages' do
    get("/cdm4/browse.php?CISOROOT=#{@item.contentdm_alias}")
    assert_response :moved_permanently
    assert_redirected_to @item.collection
  end

  test 'v4 results pages' do
    get("/cdm4/results.php?CISOROOT=#{@item.contentdm_alias}")
    assert_response :moved_permanently
    assert_redirected_to collection_items_url(@item.collection)
  end

  test 'v6 results pages' do
    get("/cdm/search/collection/#{@item.contentdm_alias}")
    assert_response :moved_permanently
    assert_redirected_to collection_items_url(@item.collection)

    get("/cdm/search/collection/#{@item.contentdm_alias}/searchterm/cats/mode/exact/order/title")
    assert_response :moved_permanently
    assert_redirected_to collection_items_url(@item.collection) + '?q=cats'

    get("/cdm/search/collection/#{@item.contentdm_alias}/searchterm/cats/mode/exact/page/2")
    assert_response :moved_permanently
    assert_redirected_to collection_items_url(@item.collection) + '?q=cats'

    get("/cdm/search/collection/#{@item.contentdm_alias}/searchterm/cats/field/subjec/mode/exact/conn/and/order/nosort")
    assert_response :moved_permanently
    assert_redirected_to collection_items_url(@item.collection) + '?q=cats'

    get("/cdm/search/collection/#{@item.contentdm_alias}/searchterm/cats/field/subjec/mode/exact/conn/and/order/nosort/page/2")
    assert_response :moved_permanently
    assert_redirected_to collection_items_url(@item.collection) + '?q=cats'
  end

  test 'v4 OAI-PMH' do
    get('/cgi-bin/oai.exe')
    assert_response :moved_permanently
    assert_redirected_to oai_pmh_url

    get('/cgi-bin/oai2.exe')
    assert_response :moved_permanently
    assert_redirected_to oai_pmh_url
  end

  test 'v4 about page' do
    get('/cdm4/about.php')
    assert_response :moved_permanently
    assert_redirected_to collections_url
  end

  test 'v4 favorites page' do
    get('/cdm4/favorites.php')
    assert_response :moved_permanently
    assert_redirected_to favorites_url
  end

  test 'v4 help page' do
    get('/cdm4/help.php')
    assert_response :moved_permanently
    assert_redirected_to root_url
  end

  test 'v4 search page' do
    get('/cdm4/search.php')
    assert_response :moved_permanently
    assert_redirected_to root_url
  end

  test 'v6 about page' do
    get('/cdm/about')
    assert_response :moved_permanently
    assert_redirected_to root_url
  end

  test 'v6 favorites page' do
    get('/cdm/favorites')
    assert_response :moved_permanently
    assert_redirected_to favorites_url
  end

  test 'v6 OAI-PMH' do
    get('/oai/oai.php')
    assert_response :moved_permanently
    assert_redirected_to oai_pmh_url
  end

  test 'v6 search page' do
    get('/cdm/search')
    assert_response :moved_permanently
    assert_redirected_to items_url
  end

  test 'v6 search results' do
    get('/cdm/search/searchterm/test')
    assert_response :moved_permanently
    assert_redirected_to search_url + '?q=test'

    get('/cdm/search/searchterm/test/mode/bogus')
    assert_response :moved_permanently
    assert_redirected_to search_url + '?q=test'

    get('/cdm/search/searchterm/test/mode/bogus/page/2')
    assert_response :moved_permanently
    assert_redirected_to search_url + '?q=test'

    get('/cdm/search/searchterm/test/mode/bogus/order/bogus')
    assert_response :moved_permanently
    assert_redirected_to search_url + '?q=test'

    get('/cdm/search/searchterm/test/mode/bogus/order/bogus/ad/desc')
    assert_response :moved_permanently
    assert_redirected_to search_url + '?q=test'
  end

end

