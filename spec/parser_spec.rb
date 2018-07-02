require 'spec_helper'

RSpec.describe Secrets::Parser do
  describe '#parse' do
    it 'returns parsed file with secrets' do
      @parser = Secrets::Parser.new
      stubbed_clients = stub_aws

      @parser.set_config do |config|
        config[:s3_client] = stubbed_clients[0]
        config[:kms_client] = stubbed_clients[1]
      end

      ENV['ACCOUNT_ALIAS'] = 'flywire-playground'
      fixture_path = "#{Dir.pwd}/spec/fixtures/app.json"
      field_to_parse = 'variables'

      parsed_file = @parser.parse(fixture_path, field_to_parse)

      expected_parsed_file = {
        'type' => 'http',
        'options' => [
        ],
        'required_services' => [
        ],
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
end
