require 'rails_helper'

RSpec.describe Internal::CheckNewVersionsJob do
  subject(:job) { described_class.perform_now }

  it 'is a no-op' do
    expect { job }.not_to raise_error
  end
end
