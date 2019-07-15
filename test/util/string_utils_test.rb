require 'test_helper'

class StringUtilsTest < ActiveSupport::TestCase

  test 'base16() works' do
    str = 'some string 123!'
    expected = '736f6d6520737472696e672031323321'
    assert_equal(expected, StringUtils.base16(str))
  end

  test 'pad_numbers works' do
    str = 'cats'
    assert_equal str, StringUtils.pad_numbers(str, '0', 5)

    str = 'cats123'
    assert_equal 'catsaa123', StringUtils.pad_numbers(str, 'a', 5)
  end

  test 'rot18 works' do
    str = 'set:8132f520-e3fb-012f-c5b6-0019b9e633c5-f|start:100|metadataPrefix:oai_dc'
    expected = 'frg:3687s075-r8so-567s-p0o1-5564o4r188p0-s|fgneg:655|zrgnqngnCersvk:bnv_qp'
    assert_equal expected, StringUtils.rot18(str)
  end

  test 'strip_leading_articles works' do
    expected = 'cat'
    # English
    assert_equal expected, StringUtils.strip_leading_articles('a cat')
    assert_equal expected, StringUtils.strip_leading_articles('A cat')
    assert_equal expected, StringUtils.strip_leading_articles('an cat')
    assert_equal expected, StringUtils.strip_leading_articles('An cat')
    assert_equal expected, StringUtils.strip_leading_articles('d\'cat')
    assert_equal expected, StringUtils.strip_leading_articles('D\'cat')
    assert_equal expected, StringUtils.strip_leading_articles('d’cat')
    assert_equal expected, StringUtils.strip_leading_articles('D’cat')
    assert_equal expected, StringUtils.strip_leading_articles('de cat')
    assert_equal expected, StringUtils.strip_leading_articles('De cat')
    assert_equal expected, StringUtils.strip_leading_articles('the cat')
    assert_equal expected, StringUtils.strip_leading_articles('The cat')
    assert_equal expected, StringUtils.strip_leading_articles('ye cat')
    assert_equal expected, StringUtils.strip_leading_articles('Ye cat')

    # French
    assert_equal expected, StringUtils.strip_leading_articles('l\'cat')
    assert_equal expected, StringUtils.strip_leading_articles('L\'cat')
    assert_equal expected, StringUtils.strip_leading_articles('l’cat')
    assert_equal expected, StringUtils.strip_leading_articles('L’cat')
    assert_equal expected, StringUtils.strip_leading_articles('la cat')
    assert_equal expected, StringUtils.strip_leading_articles('La cat')
    assert_equal expected, StringUtils.strip_leading_articles('le cat')
    assert_equal expected, StringUtils.strip_leading_articles('Le cat')
    assert_equal expected, StringUtils.strip_leading_articles('les cat')
    assert_equal expected, StringUtils.strip_leading_articles('Les cat')
  end

  test 'to_b works with true strings' do
    assert StringUtils.to_b('true')
    assert StringUtils.to_b('True')
    assert StringUtils.to_b('TRUE')
    assert StringUtils.to_b('Yes')
    assert StringUtils.to_b('1')
  end

  test 'to_b works with false strings' do
    assert !StringUtils.to_b('false')
    assert !StringUtils.to_b('False')
    assert !StringUtils.to_b('FALSE')
    assert !StringUtils.to_b('No')
    assert !StringUtils.to_b('0')
    assert !StringUtils.to_b('the quick brown fox')
  end

end
