require 'bundler/setup'
require_relative '../lib/secrets_parser/parser'
require 'aws-sdk-s3'

module Helpers
  def stub_aws
    s3_client = Aws::S3::Client.new(stub_responses: true)
    kms_client = Aws::KMS::Client.new(stub_responses: true)

    s3_client.stub_responses(:get_object, {
      body: '{"my_secret": "this_is_my_secret_peeeim"}'
    })

    kms_client.stub_responses(:decrypt, {
      plaintext: '{"my_secret": "this_is_my_secret_peeeim"}'
    })

    return s3_client, kms_client
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Helpers
end
