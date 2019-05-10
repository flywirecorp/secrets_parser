require 'aws-sdk-s3'
require 'json'
require 'logger'
require_relative 'helpers'

module Secrets
  module Errors
    class NoSuchFile < StandardError; end
  end

  class S3
    def initialize(s3_client, kms_client, logger)
      @s3_client = s3_client
      @kms_client = kms_client
      @logger = logger
    end

    def download(filename)
      bucket_name, file = filename.split('/', 2)

      @logger.info "Downloading #{file} from #{bucket_name}"
      begin
        resp = @s3_client.get_object(bucket: bucket_name, key: file)
        resp.body
      rescue Aws::S3::Errors::NoSuchKey
        raise Secrets::Errors::NoSuchFile, "Secret file #{file} does not exist in #{bucket_name}"
      end
    end

    def decrypt(io)
      @kms_client.decrypt(ciphertext_blob: io.read).plaintext
    end

    def logger
      @config.logger
    end
  end
end
