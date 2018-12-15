class CustomKeyword < Schleuder::KeywordHandlers::Base
  handles_request_keyword 'custom-keyword', with_method: :custom_keyword

  def custom_keyword
    'Something something'
  end
end
