require 'aws-sdk-s3'

RSpec.describe Secrets::Parser do
  describe '.parse' do
    let(:fixture) { "#{Dir.pwd}/spec/fixtures/app.json" }
    let(:field) { 'variables' }
    let(:secret_file) { 'apps/secret-testing.json.encrypted' }
    let(:bucket_name) { 'a-bucket' }
    let(:secret_keys) { %w(MY_SECRET MY_SECRET2) }

    it 'logs information when a logger is injected' do
      logger = instance_double(Logger)
      parser = build_default_parser.set_config do |config|
        config[:logger] = logger
      end

      expect(logger).to receive(:info).with("Parsing #{field} section of #{fixture}")
      expect(logger).to receive(:info).with("Downloading #{secret_file} from #{bucket_name}")
      secret_keys.each do |secret_key|
        expect(logger).to receive(:info).with("Updating #{secret_key} value")
      end

      parser.parse(fixture, field)
    end

    it 'logs error when secret file does not exists' do
      logger = spy('logger')
      s3_client_stub = stub_aws[0]

      parser = build_default_parser.set_config do |config|
        config[:s3_client] = s3_client_stub
        config[:logger] = logger
      end

      allow(s3_client_stub).to receive(:get_object)
        .and_raise(Aws::S3::Errors::NoSuchKey.new('', ''))

      expected_error_message = "Secret file #{secret_file} does not exist in #{bucket_name}"

      expect { parser.parse(fixture, field) }
        .to raise_error(Secrets::Errors::NoSuchFile, expected_error_message)
    end

    it 'returns parsed file with secrets' do
      parser = build_default_parser

      fixture_path = "#{Dir.pwd}/spec/fixtures/app.json"
      field_to_parse = 'variables'

      parsed_file = parser.parse(fixture_path, field_to_parse)

      expected_parsed_file = {
        'type' => 'http',
        'options' => [],
        'required_services' => [],
        'variables' => {
          'MY_SECRET' => 'this_is_my_secret_peeeim',
          'MY_SECRET2' => 'this_is_my_secret_peeeim',
          'NOT_A_SECRET' => 123,
          'NO_SECRETS_HERE' => 'PINCODE: Just joking'
        }
      }

      expect(expected_parsed_file).to eq parsed_file
    end

    it 'logs error when secret key does not exists' do
      logger = spy('logger')

      parser = build_default_parser.set_config do |config|
        config[:logger] = logger
      end

      key_name = 'my_missing_secret'
      fixture_path = "#{Dir.pwd}/spec/fixtures/app_with_missing_secret.json"

      expected_error_message = "Secret key #{key_name} does not exist in #{bucket_name}/apps/secret-testing"

      expect { parser.parse(fixture_path, field) }
        .to raise_error(Secrets::Errors::NoSuchKey, expected_error_message)
    end

    def build_default_parser
      ENV['AWS_DEFAULT_REGION'] = 'eu-west-1'

      parser = Secrets::Parser.new
      stubbed_clients = stub_aws

      parser.set_config do |config|
        config[:s3_client] = stubbed_clients[0]
        config[:kms_client] = stubbed_clients[1]
      end
    end
  end
end
