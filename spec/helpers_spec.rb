require 'spec_helper'

RSpec.describe Secrets::Helpers do
  describe '#expand_param_from_env' do
    it 'should parse the ENV variable' do
      ENV['ACCOUNT_ALIAS'] = 'flywire-playground'

      value = '$ACCOUNT_ALIAS-rocks'
      expected_value = 'flywire-playground-rocks'

      parsed_value = described_class.expand_param_from_env(value)

      expect(parsed_value).to eq expected_value
    end
  end
end
