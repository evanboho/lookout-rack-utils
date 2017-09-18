require 'spec_helper'
require 'lookout/rack/utils/i18n'

class TestHelper
  attr_accessor :locale
  attr_accessor :request
  attr_accessor :configatron

  include Lookout::Rack::Utils::I18n

  def initialize
  end
end

describe Lookout::Rack::Utils::I18n do
  let(:helper) { TestHelper.new }

  describe '.t' do
    let(:args) { double('mock arguments') }

    before :each do
      expect(::I18n).to receive(:t).with(args)
    end

    it 'should call out to ::I18n.t' do
      helper.t(args)
    end
  end

  describe 'accepted_languages' do
    subject { helper.accepted_languages }

    before :each do
      helper.request = Object.new
      expect(helper.request).to receive(:env).and_return({'HTTP_ACCEPT_LANGUAGE' => accepted_langs})
    end    

    context 'if HTTP_ACCEPT_LANGUAGE is not set' do
      let(:accepted_langs) { nil }

      it { should be_empty }
    end

    context 'if HTTP_ACCEPT_LANGUAGE is set' do
      # Example borrowed from http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
      let(:accepted_langs) { 'da, en-gb;q=0.8, en;q=0.7' }

      it { should_not be_empty }
    end
  end

  describe '.current_locale' do
    let(:target_locale) { 'target locale' }
    let(:default_locale) { 'default locale' }
    let(:accepted_langs) { [target_locale] }

    before :each do
      allow(helper).to receive(:accepted_languages).and_return(accepted_langs)
    end

    subject (:current_locale) { helper.current_locale }

    context 'if locale is not nil' do
      before :each do
        helper.locale = target_locale
      end

      it { should eql target_locale }
    end
    
    context 'if locale is nil' do
      context 'if configatron does not contain any of the accepted langs' do
        before :each do
          helper.configatron = Object.new
          expect(helper.configatron).to receive(:locales).and_return([])
          expect(helper.configatron).to receive(:default_locale).and_return(default_locale)
        end

        it { should eql default_locale }
      end

      context 'if configatron.locales contains one of the accepted languages' do
        before :each do
          helper.configatron = Object.new
          expect(helper.configatron).to receive(:locales).and_return([target_locale])
        end

        it { should eql target_locale }
      end
    end
  end
end
