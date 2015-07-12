require 'spec_helper'
require 'celluloid/test'

class InterestedParty
  include ImapMonitor::EmailEvent::Observer

  def property_changed(clazz, prop, value)
    calls << "#{clazz}, property: #{prop}, value: #{value.subject}"
  end

  def calls
    @calls ||= []
  end
end

describe 'Email Tracker' do
  let(:options) {{ host: 'smtp.blah', post: '993', use_ssl: false }}
  let(:connector) { ImapMonitor::Connector.new(options) }
  subject { ImapMonitor::Email::Tracker.new(connector) }

  it { expect(subject.respond_to?(:register)).to be_truthy }
  it { expect(subject.respond_to?(:deregister)).to be_truthy }
  it { expect(subject.respond_to?(:listeners)).to be_truthy }
  it { expect(subject.respond_to?(:fire_change)).to be_truthy }

  describe '#initialize' do
    it 'assigns variables with params' do
      subject = ImapMonitor::Email::Tracker.new(connector, {directory: 'TEST'})
      expect(subject.instance_variable_get(:@options)).to eq({directory: 'TEST'})
      expect(subject.instance_variable_get(:@connector)).to eq connector
    end

    it 'defaults the options hash with directory value' do
      expect(subject.instance_variable_get(:@options)).to eq({directory: 'INBOX'})
    end
  end

  describe '#received_emails' do
    it 'returns an empty array when @received_emails is nil' do
      expect(subject.received_emails).to eq []
    end

    it 'returns an array of emails' do
      subject.received_emails << 'Mail1'
      expect(subject.received_emails).to eq ['Mail1']

      subject.received_emails << 'Mail2'
      expect(subject.received_emails).to eq ['Mail1', 'Mail2']
    end
  end

  describe '#start' do
    before(:each) do
      subject.wrapped_object.instance_eval do
        def fetch_emails(range)
          []
        end
      end
    end

    it 'starts monitoring and updates states' do
      expect(subject.monitoring?).to be_falsy
      expect(subject.started_at).to be_nil

      subject.async.start

      expect(subject.started_at).not_to be_nil
      expect(subject.monitoring?).to be true
    end

    it 'prevents track being called twice when already monitoring' do
      expect(subject.async.start).to be_nil
      expect(subject.start).to eq "Current monitor in progress since #{subject.started_at}"
    end
  end

  describe '#update_or_create_uid' do
    let(:fetched) { [Net::IMAP::FetchData.new(1, "UID" => 0), Net::IMAP::FetchData.new(1, "UID" => 1)] }

    it 'returns last Net::IMAP::FetchData instance' do
      expect(subject.send(:update_or_create_uid, fetched)).to eq fetched.last
    end

    it 'returns a default fetch data instance when parameter nil' do
      expect(subject.send(:update_or_create_uid, [])).to eq Net::IMAP::FetchData.new(1, "UID" => 0)
    end

    it 'returns a default fetch data instance when parameter is an empty array' do
      expect(subject.send(:update_or_create_uid, nil)).to eq Net::IMAP::FetchData.new(1, "UID" => 0)
    end
  end

  describe '#track' do
    let(:observer) { InterestedParty.new }
    subject { ImapMonitor::Email::Tracker.new(connector) }

    before(:each) do
      Celluloid.shutdown
      Celluloid.boot

      subject.wrapped_object.instance_eval do
        def update_or_create_uid(fetch_data)
          Net::IMAP::FetchData.new(1, "UID" => 0)
        end
      end

      subject.wrapped_object.instance_eval do
        def create_mail(seqno)
          Mail.new({from: "test@test#{seqno}.com", to: "to@test.com", subject: "Seq: #{seqno}"})
        end
      end

      subject.wrapped_object.instance_eval do
        def fetch_emails(range)
          data = []
          data << Net::IMAP::FetchData.new(1000000, "UID" => 3)
          data << Net::IMAP::FetchData.new(1000001, "UID" => 4)
          data << Net::IMAP::FetchData.new(1000002, "UID" => 2)
          data << Net::IMAP::FetchData.new(1000003, "UID" => 6)
          data
        end
      end

      subject.register(observer)
    end

    it 'fires updates to observers and adds to list when new email processed' do
      subject.async.start

      # Little pause so the current thread doesn't jump ahead of the async thread
      while(subject.received_emails.size < 3)
      end

      expect(subject.received_emails.size).to eq 3
      expect(observer.calls.size).to eq 3

      expect(observer.calls[0]).to eq "ImapMonitor::Email::Tracker, property: NewMail, value: Seq: 1000000"
      expect(observer.calls[1]).to eq "ImapMonitor::Email::Tracker, property: NewMail, value: Seq: 1000001"
      expect(observer.calls[2]).to eq "ImapMonitor::Email::Tracker, property: NewMail, value: Seq: 1000003"
    end
  end

  describe '#stop' do
    before(:each) do
      subject.wrapped_object.instance_eval do
        def fetch_emails(range)
          []
        end
      end
    end

    it 'updates monitoring to false' do
      expect(subject.connector).to receive(:logout).once

      subject.async.start
      expect(subject.monitoring?).to eq true

      subject.stop
      expect(subject.monitoring?).to eq false
    end
  end
end
