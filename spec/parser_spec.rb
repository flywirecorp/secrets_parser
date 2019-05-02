RSpec.describe Secrets::Parser do
  describe 'as an operable artifact' do
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

    def fixture
      "#{Dir.pwd}/spec/fixtures/app.json"
    end

    def field
      'variables'
    end

    def secret_file
      'apps/secret-testing.json.encrypted'
    end

    def bucket_name
      'a-bucket'
    end

    def secret_keys
      %w(MY_SECRET MY_SECRET2)
    end
  end

  describe '#parse' do
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
