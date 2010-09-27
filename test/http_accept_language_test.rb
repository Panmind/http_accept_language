$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'http_accept_language'
require 'test/unit'

class MockedCgiRequest
  include HttpAcceptLanguage
  def env
    @env ||= {'HTTP_ACCEPT_LANGUAGE' => 'it;q=0.4,en-us, en-gb;q=0.8,en;q=0.6, de;q=2, invalid;q=1, xx;q=30,, ., .'}
  end
end

class HttpAcceptLanguageTest < Test::Unit::TestCase
  def test_should_return_empty_array
    request.env['HTTP_ACCEPT_LANGUAGE'] = nil
    assert_equal [], request.user_preferred_languages
  end

  def test_should_properly_split
    assert_equal %w{en-US en-GB en it}, request.user_preferred_languages
  end

  def test_should_ignore_jambled_header
    request.env['HTTP_ACCEPT_LANGUAGE'] = 'odkhjf89fioma098jq .,.,'
    assert_equal [], request.user_preferred_languages
  end

  def test_should_find_first_available_language
    assert_equal 'en-GB', request.preferred_language_from(%w{en en-GB})
  end

  def test_should_find_first_compatible_language
    assert_equal 'en', request.compatible_language_from(%w{en-hk en-GB en})
    assert_equal 'it', request.compatible_language_from(%w{it de})
  end

  def test_should_find_first_compatible_from_user_preferred
    request.env['HTTP_ACCEPT_LANGUAGE'] = 'en-us,de-de'
    assert_equal 'en', request.compatible_language_from(%w{de en})
  end

  def test_should_find_first_compatible_from_user_preferred_in_order
    request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-de, en-us'
    assert_equal 'de', request.compatible_language_from(%w{de en})
  end
  
  def test_should_accept_symbols_as_available_languages
    request.env['HTTP_ACCEPT_LANGUAGE'] = 'en-us'
    assert_equal 'en', request.compatible_language_from([:en, :de])
  end

  private
  def request
    @request ||= MockedCgiRequest.new
  end
end
