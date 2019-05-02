require 'aws-sdk-s3'
require 'json'
require 'logger'
require_relative 'helpers'

module Secrets
  class Parser
    SECRETS_FILE_SUFFIX = '.json.encrypted'.freeze

    class Configuration
      SETTINGS = %i[s3_client kms_client logger].freeze

      attr_accessor(*SETTINGS)

      def []=(key, value)
        public_send("#{key}=", value)
      end
    end

    def initialize
      @config = Configuration.new
    end

    def set_config
      yield(@config)
      @config.logger ||= Logger.new(File::NULL)
      self
    end

    def parse(file_to_parse, field_to_parse)
      Aws.config.update(
        region: ENV['AWS_DEFAULT_REGION']
      )

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

    def download(filename)
      bucket_name, file = filename.split('/', 2)
      file += SECRETS_FILE_SUFFIX

      logger.info "Downloading #{file} from #{bucket_name}"

      resp = @config.s3_client.get_object(bucket: bucket_name, key: file)
      resp.body
    end

    def decrypt(io)
      kms = @config.kms_client

      kms.decrypt(ciphertext_blob: io.read).plaintext
    end

    def extract_secrets_from(secret_file)
      encrypted_secrets_io = download(secret_file)
      decrypted_secrets = decrypt(encrypted_secrets_io)

      JSON.parse(decrypted_secrets)
    end

    def parse_secrets_from(variables)
      secret_variables = {}

      variables.each_pair do |key, value|
        next unless secret?(value)

        _, secret_file, secret_key = value.split(':')

        secret_file = Helpers.expand_param_from_env(secret_file)

        unless already_decrypted?(secret_variables, secret_file)
          secret_variables[secret_file] = extract_secrets_from(secret_file)
        end

        logger.info "Updating #{key} value"

        variables[key] = secret_variables[secret_file][secret_key]
      end

      variables
    end

    def already_decrypted?(secret_variables, secret_file)
      secret_variables.key?(secret_file)
    end

    def logger
      @config.logger
    end
  end
end
