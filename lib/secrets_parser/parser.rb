require 'json'
require 'aws-sdk-s3'
require_relative 'helpers'

module Secrets
  class Parser
    SECRETS_FILE_SUFFIX = '.json.encrypted'.freeze

    def initialize
      @config = {
        s3_client: nil,
        kms_client: nil,
        logger: nil
      }
    end

    def set_config
      yield @config
    end

    def parse(file_to_parse, field_to_parse)
      Aws.config.update(
        region: ENV['AWS_DEFAULT_REGION']
      )

      app_json = JSON.parse(IO.read(file_to_parse))
      app_variables = app_json[field_to_parse]

      logger.info "Parsing #{field_to_parse} section of #{file_to_parse}" if logger?

      app_json[field_to_parse] = parse_secrets_from app_variables

      app_json
    end

    private

    def secret?(string)
      if string.is_a? String
        string.start_with? 'secret:'
      else
        false
      end
    end

    def secret_file_path_from(secret)
      secret_file_path = secret[secret.index(':') + 1..secret.rindex(':') - 1]
      Helpers.expand_param_from_env secret_file_path
    end

    def secret_key_from(secret)
      secret[secret.rindex(':') + 1..secret.length]
    end

    def download(file)
      bucket_name = file[0, file.index('/')]
      file = file[file.index('/') + 1..file.length] + SECRETS_FILE_SUFFIX
      tmp_file = "/tmp/secrets#{SECRETS_FILE_SUFFIX}"

      logger.info "Downloading #{file} from #{bucket_name}" if logger?

      File.open(tmp_file, 'wb') do |secret_file|
        @config[:s3_client].get_object({ bucket: bucket_name, key: file }, target: secret_file)
      end

      tmp_file
    end

    def decrypt(file)
      kms = @config[:kms_client]

      kms.decrypt(
        ciphertext_blob: IO.read(file)
      )
    end

    def extract_secrets_from(secret_file)
      encrypted_secrets_file = download secret_file
      decrypted_secrets_file = decrypt encrypted_secrets_file

      JSON.parse(decrypted_secrets_file.plaintext)
    end

    def parse_secrets_from(variables)
      secret_variables = {}

      variables.each_pair do |key, value|
        next unless secret?(value)

        secret = value

        secret_file = secret_file_path_from(secret)
        secret_key = secret_key_from(secret)

        unless secret_variables.key?(secret_file)
          secret_variables[secret_file] = extract_secrets_from secret_file
        end

        logger.info "Updating #{key} value" if logger?

        variables[key] = secret_variables[secret_file][secret_key]
      end

      variables
    end

    def logger?
      !logger.nil?
    end

    def logger
      @config[:logger]
    end
  end
end
