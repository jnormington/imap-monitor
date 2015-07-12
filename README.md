#IMAP Monitor

In most scenarios we rely on email communication from most web applications using it for

- marketing
- updates to T&C
- custom user alerts

In all cases there different approaches on how we implement the sending of these emails suchas
 - external companies
 - background processes (different implementation variations)

This allows you to check that; 

a) The external company can handle such loads within a time frame and there are not any email dropouts.

b) If internally sending the background process implementation is the correct for the long term load.

c) It can and also be used for testing from the outside and emails contain links to continue the journey.


##Getting Started
 - Clone the repository
 - cd into the cloned directory
 - `gem build imap_monitor.gemspec`
 - `gem install imap_monitor-0.1.0.gem`

 - Write your own observer to handle what happens when new emails arrive mathcing a criteria. You can have multiple observers running against one Email::Tracker.
 - Small example of what would get you up and running.

```ruby
require 'imap_monitor'

class ExampleObserver
  # Not required - but it there should you want to.
  include ImapMonitor::EmailEvent::Observer

  def initialize
    #Not recommended but just an example
    account = {
      host: 'imap.gmail.com',
      port: 993,
      username: 'email',
      password: 'password',
      use_ssl: true
    }

    @tracker = ImapMonitor::Email::Tracker.new(ImapMonitor::Connector.new(account))
    @tracker.register(self)
  end

  def go
    begin
      tracker.async.start

       trap "SIGINT" do
         raise 'Cancelled by user'
       end
    rescue => e
      puts 'Stopping tracker'
      tracker.stop rescue nil
      puts e.inspect
    end
  end

  def tracker
    @tracker
  end

  def property_changed(clazz, property, email)
    if email.subject.include? 'Test'
      puts 'Email received.... '
      # Extract the contents and a link
      # for another test to continue
    else
     # ignore
    end

    tracker.stop if tracker.received_emails.size == 2
  end
end

ExampleObserver.new.go

```

 - Once you have your observer you can can just call it in the following way from the command line `ruby example_observer_file_name.rb`
 - As we have `ExampleObserver.new.go` at the bottom it will initialize and start and when 2 emails are received the email observer will instruct the tracker stop.
 - If you want to stop it earlier with CTRL+C then you can and it will be caught and call stop on the tracker. (Implemented in the observer)

##Tests
 - When running `rpsec` on the cloned repository it will run all the unit specs.
 - There is a smoke directory under the specs which isn't ran during calling `rpsec`, this smoke test needs to be run specially with the following

`rspec spec/smoke/imap_monitor_smoke.rb`

 - But before you do run the above, you will need to input your imap/ email account details for it to run on line 29.

```
 let(:details) {{ host: 'imap.gmail.com', port: 993, username: 'email', password: 'password', use_ssl: true }}
```

 - When you run the spec - it will continously run until it receives an email - this is where you come in. Send an email to yourself. Once it receives one email it will stop itself and report a pass (or fail - if multiple are received in short succession.)

##Limitations

 - You can't rely on any current email host suchas google mail because there is throttling to the one email address in such large volumes. 
 - In this case a postfix
 email server should be setup with a mutt email client on a Ubuntu box for a realistic and un-throttled email receiptant.

##Licence
IMAP Monitor is released under the MIT License.
