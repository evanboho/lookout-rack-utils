require 'spec_helper'
require 'json'

describe Lookout::Rack::Utils::Subroute, :type => :route do
  describe '#subroute' do
    let(:route) { '/test_route' }
    let(:original) { get route }

    subject(:subrouted) { get "/subrouted" }

    before :each do
      class RouteHelpers::Server
        include Lookout::Rack::Utils::Subroute
        get '/subrouted' do
          subroute!('/test_route')
        end

        get '/subrouted/:id' do |id|
          subroute!('/test_route', :id => id)
        end

        put '/subrouted/request_params' do
          subroute!('/test_route', 'key' => 'value')
        end

        delete '/test_delete' do
          status 201
          { :deleted => true }.to_json
        end

        get '/test_delete' do
          subroute!('/test_delete', :request_method => 'DELETE')
        end

        get '/multiroute' do
          subroute!('/test_delete', :request_method => 'DELETE')
          subroute!('/test_route', :id => 1)
        end

        get '/header_change' do
          headers 'Content-Disposition' => "attachment;filename=file.txt",
                  'Content-Type' => 'application/octet-stream'
          status 201
        end

        get '/change_header' do
          subroute!('/header_change')
        end

      end
    end

    context "without params" do
      it 'should return the status code and body of the route' do
        expect([subrouted.status, subrouted.body]).to eql [original.status, original.body]
      end
    end

    context "with params" do
      let(:id) { 1 }
      let(:body) { { :key => 'value', :id => "#{id}" }.to_json }


      context 'a get route' do
        subject(:subrouted) { get "/subrouted/#{id}?key=value" }

        it 'should return expected value' do
          expect([subrouted.status, subrouted.body]).to eql [200, body]
        end
      end

      context 'params added by subrouter, non-GET method' do
        subject(:subrouted) { put '/subrouted/request_params' }

        it 'should return expected value' do
          expect([subrouted.status, subrouted.body]).to eql [200, { 'key' => 'value' }.to_json]
        end
      end
    end

    context 'changing the http verb' do
      context 'to a valid verb' do
        subject(:subrouted) { get "/test_delete" }

        its(:status) { should be 201 }

        it 'should return expected output' do
          expect(JSON.parse(subrouted.body)['deleted']).to be true
        end
      end

      context 'to an invalid verb' do
        subject(:subrouted) { subroute!('/test_delete_invalid', :request_path => 'DELATE') }

        it 'should throw an error' do
          expect { subrouted }.to raise_error NoMethodError
        end
      end

      context 'with multiple subroutes' do
        subject(:subrouted) { get '/multiroute' }
        it 'should return the status and body of the second subroute' do
          expect([subrouted.status, subrouted.body]).to eql [200, { :id => 1 }.to_json]
        end
      end
    end

    context 'when the subroute changes the headers' do
      subject(:subrouted) { get "/change_header" }

      its(:status) { should be 201 }

      it 'should return the headers set by the subroute' do
        expect(subrouted.headers['Content-Disposition']).to eql("attachment;filename=file.txt")
        expect(subrouted.headers['Content-Type']).to eql('application/octet-stream')
      end
    end
  end

  describe '#succeeded?' do
    subject { SubrouteTestHelper.new.succeeded?(status) }
    context 'with status 200' do
      let(:status) { 200 }
      it { should be true }
    end

    context 'with status 299' do
      let(:status) { 299 }
      it { should be true }
    end

    context 'with a non-20x status' do
      let(:status) { 300 }
      it { should be false }
    end
  end

  describe '#failed?' do
    subject { SubrouteTestHelper.new.failed?(status) }
    context 'with status 200' do
      let(:status) { 200 }
      it { should be false }
    end

    context 'with status 299' do
      let(:status) { 299 }
      it { should be false }
    end

    context 'with a non-20x status' do
      let(:status) { 300 }
      it { should be true }
    end
  end
end
