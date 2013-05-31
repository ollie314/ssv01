require 'net/http'
require 'uri'

module Checker
  class LinkChecker

    def is_live?(url)
      get_code(url) == '200'
    end

    def get_code(url)
      uri = URI.parse(url)
      response = nil
      Net::HTTP.start(uri.port) { |http|
        response = http.head(uri.path.size > 0 ? uri.path : '/')
      }
      response.code
    end
  end
end
