require 'spec_helper.rb'

class ExampleObserver
  include ImapMonitor::EmailEvent::Observer

  def initialize(account = {})
    @tracker = ImapMonitor::Email::Tracker.new(ImapMonitor::Connector.new(account))
    @tracker.register(self)
  end

  def go
    tracker.async.start
    puts "Tracker started..."
  end

  def tracker
    @tracker
  end

  def custom
    @custom ||= []
  end

  def property_changed(clazz, property, email)
    puts 'Property Change Received'
    @custom << "#{property}, #{email.subject}"
  end
end

describe 'Imap monitor smoken test' do
  let(:details) {{ host: 'imap.gmail.com', port: 993, username: 'email', password: 'password', use_ssl: true }}
  let(:observer) { ExampleObserver.new(details) }

  it 'receives one call to the observer with the email' do
    observer.go

    while(observer.custom.size == 0)
    end

    observer.tracker.stop
    expect(observer.tracker.connector.connection.disconnected?).to eq false
    expect(observer.custom.size).to eq 1
    expect(observer.custom.first).to include 'NewMail'
  end
end
