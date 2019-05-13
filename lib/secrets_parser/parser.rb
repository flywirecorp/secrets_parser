require 'aws-sdk-s3'
require 'json'
require 'logger'
require_relative 'helpers'
require_relative 's3'

module Secrets
  module Errors
    class NoSuchKey < StandardError; end
  end

  class Parser
    SECRETS_FILE_SUFFIX = '.json.encrypted'.freeze

    class Configuration
      SETTINGS = %i[s3_client kms_client logger s3].freeze

      attr_accessor(*SETTINGS)

      def []=(key, value)
        public_send("#{key}=", value)
      end
    end

    def initialize
      @config = Configuration.new
      @secret_variables = {}
    end

    def set_config
      yield(@config)
      @config.logger ||= Logger.new(File::NULL)
      self
    end

    def parse(file_to_parse, field_to_parse)
      @config.s3 = S3.new(@config.s3_client, @config.kms_client, @config.logger)

      app_json = JSON.parse(IO.read(file_to_parse))
      app_variables = app_json[field_to_parse]

      logger.info "Parsing #{field_to_parse} section of #{file_to_parse}"

      app_json[field_to_parse] = parse_secrets_from app_variables

      app_json
    end

    private

    def secret?(string)
      string.is_a?(String) && string.start_with?('secret:')
    end

    def secrets_from(secret_file)
      return @secret_variables[secret_file] if already_decrypted?(secret_file)

      encrypted_secrets_io = @config.s3.download(secret_file + SECRETS_FILE_SUFFIX)
      decrypted_secrets = @config.s3.decrypt(encrypted_secrets_io)

      JSON.parse(decrypted_secrets)
    end

    def parse_secrets_from(variables)
      variables.each_pair do |key, value|
        next unless secret?(value)

        secret_file = secret_file_from(value)
        secret_key = secret_key_from(value)

        @secret_variables[secret_file] = secrets_from(secret_file)

        logger.info "Updating #{key} value"
        variables[key] = secret_value_from(secret_file, secret_key)
      end

      variables
    end

    def already_decrypted?(secret_file)
      @secret_variables.key?(secret_file)
    end

    def secret_file_from(secret)
      Helpers.expand_param_from_env(secret).split(':')[1]
    end

    def secret_key_from(secret)
      Helpers.expand_param_from_env(secret).split(':')[2]
    end

    def secret_value_from(secret_file, secret_key)
      unless secret_key_exists?(secret_file, secret_key)
        raise Secrets::Errors::NoSuchKey, "Secret key #{secret_key} does not exist in #{secret_file}"
      end

      @secret_variables[secret_file][secret_key]
    end

    def secret_key_exists?(secret_file, secret_key)
      !@secret_variables[secret_file][secret_key].nil?
    end

    def logger
      @config.logger
    end
  end
end
