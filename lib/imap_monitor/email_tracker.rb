require 'mail'
require 'celluloid'

module ImapMonitor
  module Email
    class Tracker
      include Celluloid
      include EmailEvent::Observable

      attr_reader :options, :connector, :started_at

      finalizer :stop

      def initialize(connector, options = {:directory => 'INBOX'})
        @connector = connector
        @options = options
      end

      def recieved_emails
        @recieved_emails ||= []
      end

      def start
        if monitoring?
          "Current monitor in progress since #{started_at}"
        else
          track
        end
      end

      def monitoring?
        @monitoring && !@started_at.nil?
      end

      def stop
        @monitor = false
        @started_at = nil
        @connector.logout
      end

      private

      def track
        last_uid = update_or_create_uid(fetch_emails(1))
        update_to_started_state

        while (monitoring?)
          emails = fetch_emails(last_uid.seqno..-1)

          if !emails.nil?
            emails.each do |fetched_data|
              if fetched_data.attr["UID"] > last_uid.attr["UID"]
                new_mail = create_mail(fetched_data.seqno)
                recieved_emails << new_mail
                last_uid = fetched_data unless fetched_data.nil?
                fire_change("NewMail", new_mail)
              end
            end
          end

          sleep(1)
        end
      end

      def fetch_emails(range)
        connector.connection.examine(options[:directory])
        connector.connection.fetch(range..-1, "UID")
      end

      def update_to_started_state
        @started_at = Time.now
        @monitoring = true
      end

      def create_mail(mail_seqno)
        Mail.read_from_string(
          connector.connection.fetch(mail_seqno, 'RFC822')[0].attr['RFC822'])
      end

      def update_or_create_uid(fetch_data)
         if fetch_data.nil? || fetch_data.empty?
           Net::IMAP::FetchData.new(1, "UID" => 0)
         else
          fetch_data.last
         end
      end
    end
  end
end
