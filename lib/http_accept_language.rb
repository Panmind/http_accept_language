module HttpAcceptLanguage

  # Returns a sorted array based on user preference in sent via
  # the Accept-Language HTTP header. Don't think this is holy!
  #
  # Returns an empty array if the header does not contain any
  # parsable language code.
  #
  # Example:
  #
  #   Accept-Language: en;q=0.3, nl-NL, nl-be;q=0.9, en-US;q=0.5
  #
  #   request.user_preferred_languages
  #   # => [ 'nl-NL', 'nl-BE', 'nl', 'en-US', 'en' ]
  #
  def user_preferred_languages
    @user_preferred_languages ||= env['HTTP_ACCEPT_LANGUAGE']
      .scan(/\b([a-z]{2}(?:-[a-z]{2})?)(?:;q=([01](?:\.\d)?))?\s*($|,)/)
      .sort_by {|l, pref| 1 - (pref || 1).to_f}
      .map! {|l,| l.downcase.sub(/-\w{2}/) { $&.upcase } }

  rescue # Just rescue anything if the browser messed up badly.
    []
  end

  # Returns a sorted array of language codes symbols based on user's
  # browser preference sent via the Accept-Language HTTP header.
  #
  # Example:
  #
  #   Accept-Language: en;q=0.3, nl-NL, nl-be;q=0.9, en-US;q=0.5
  #
  #   request.user_preferred_languages
  #   # => [ :nl, :en ]
  #
  def user_preferred_language_codes
    @user_preferred_language_codes ||=
      strip_region_from user_preferred_languages
  end

  # Sets the user languages preference, overiding the browser
  #
  def user_preferred_languages=(languages)
    @user_preferred_languages = languages
    @user_preferred_language_codes = nil
  end

  # Finds the locale specifically requested by the browser.
  #
  # Example:
  #
  #   request.preferred_language_from I18n.available_locales
  #   # => 'nl'
  #
  def preferred_language_from(array)
    (user_preferred_languages & array.collect { |i| i.to_s }).first
  end

  # Returns the first of the user_preferred_languages that
  # is included into the given array, ignoring region.
  #
  # Useful with Rails' I18n.available_locales.
  #
  # Example:
  #
  #   Accept-Language: en;q=0.3, nl-NL, nl-be;q=0.9, en-US;q=0.5
  #
  #   request.compatible_language_from [:nl, :it]
  #   # => 'nl'
  #
  def compatible_language_from(array)
    (user_preferred_language_codes & strip_region_from(array)).first
  end

  private
    def strip_region_from(languages)
      languages.map {|l| l.to_s.sub(/-\w{2}/, '')}.uniq
    end
end
if defined?(ActionDispatch::Request)
  ActionDispatch::Request.send :include, HttpAcceptLanguage
elsif defined?(ActionDispatch::AbstractRequest)
  ActionDispatch::AbstractRequest.send :include, HttpAcceptLanguage
elsif defined?(ActionDispatch::CgiRequest)
  ActionDispatch::CgiRequest.send :include, HttpAcceptLanguage
end
