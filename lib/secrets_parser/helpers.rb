module Secrets
  module Helpers
    def self.expand_param_from_env(value)
      dollar_match_expression = /\$([A-Za-z0-9_]*)/
      value.scan(dollar_match_expression).each do |match|
        break unless ENV.include? match[0]
        value = value.gsub("$#{match[0]}", ENV[match[0]])
      end
      value
    end
  end
end
