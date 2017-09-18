require 'spec_helper'
require 'lookout/rack/utils/request'
require 'zlib'

class TestHelper
  attr_accessor :request

  include Lookout::Rack::Utils::Request

  def initialize
  end
end


describe Lookout::Rack::Utils::Request do
  let(:helper) { TestHelper.new }
  let(:sample_data) {'i am groot'}
  let(:zipped_sample_data){Zlib::Deflate.deflate(sample_data)}
  let(:log_instance) { double('Lookout::Rack::Utils::Log') }

  describe '#gunzipped_body' do

    before :each do
      helper.request = Object.new
      allow(helper.request).to receive(:env).and_return({'HTTP_CONTENT_ENCODING' => 'gzip'})
      allow(helper.request).to receive(:body).and_return(double)
      allow(helper.request.body).to receive(:rewind).and_return(double)
    end

    it 'should unzip data zipped data properly' do
      expect(helper.request.body).to receive(:read).and_return(zipped_sample_data)
      expect(helper.gunzipped_body).to eq(sample_data)
    end

    it 'should do nothing if encoding is not set' do
      expect(helper.request).to receive(:env).and_return({})
      expect(helper.request.body).to receive(:read).and_return(zipped_sample_data)
      expect(helper.gunzipped_body).to eq(zipped_sample_data)
    end

    it 'should halt and throw and 400 when we have badly encoded data' do
      allow(Lookout::Rack::Utils::Log).to receive(:instance).and_return(log_instance)
      expect(log_instance).to receive(:warn)
      expect(helper.request.body).to receive(:read).and_return(sample_data)
      expect(helper).to receive(:halt).with(400, "{}")
      helper.gunzipped_body
    end
  end

end
