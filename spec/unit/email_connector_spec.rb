require 'spec_helper'

class Net::IMAP
  def initialize(host,port,blah)
  end

  def login(user,pass)
    self
  end

  def disconnected?
  end

  def disconnect
  end

  def logout
  end
end

describe 'EmailConnector' do
  let(:options) {{ host: 'smtp.blah', post: '993', use_ssl: false }}
  subject { ImapMonitor::Connector.new(options) }

  describe '#initialize' do
    subject { ImapMonitor::Connector }
    let(:error_text) { 'Hash of options required for a connection' }

    it 'raises an exception when no arguments are passed' do
      expect{ subject.new }.to raise_error ArgumentError, error_text
    end

    it 'raises an exception when a hash isnt passed' do
      expect{ subject.new('Options') }.to raise_error ArgumentError, error_text
    end

    it 'stores the options hash passed' do
      expect(subject.new(options).send(:options)).to eq options
    end
  end

  describe '#connect' do
    let(:faker_net_imap) { Net::IMAP.new(1,2,3) }

    it 'makes a connection when imap is nil' do
      expect(subject.send(:imap)).to be_nil

      subject.connection
      expect(subject.send(:imap)).not_to be_nil
    end

    it 'makes a connection when imap is disconnected' do
      net_instance = subject.connection
      expect(net_instance).to be_eql net_instance

      allow(net_instance).to receive(:disconnected?) { true }

      new_net_instance = subject.connection
      expect(new_net_instance).not_to be_eql net_instance
    end

    it 'returns the connection when imap disconnected is false' do
      imap_instance = subject.connection
      expect(imap_instance).to be_eql imap_instance

      allow(imap_instance).to receive(:disconnected?) { false }

      new_imap_instance = subject.connection
      expect(new_imap_instance).to be_eql imap_instance
    end
  end

  describe '#logout' do
    it 'doesnt raise an exception when the stream is closed' do
      imap = subject.connection
      allow(imap).to receive(:disconnected?) { true }
      allow(imap).to receive(:logout) { raise IOError, 'closed stream' }

      expect{ subject.logout }.not_to raise_error IOError
    end

    it 'doesnt raise an exception when the instance is nil' do
      allow(subject).to receive(:imap) { nil }
      expect{ subject.logout }.not_to raise_error NoMethodError
    end

    it 'calls logout and disconnect when connected' do
      imap = subject.connection
      allow(imap).to receive(:disconnected?) { false }
      allow(imap).to receive(:disconnect) { nil }
      allow(imap).to receive(:logout) { nil }

      expect(imap).to receive(:logout).once
      expect(imap).to receive(:disconnect).once

      subject.logout
    end
  end
end
