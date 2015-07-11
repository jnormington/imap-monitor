require 'net/imap'

module ImapMonitor
  class Connector
    def initialize(opts = {})
      if !opts.is_a?(Hash) || (opts.keys.empty? || opts.values.empty?)
        raise ArgumentError, "Hash of options required for a connection"
      end

      @options = opts
    end

    def connection
      connect if imap.nil? || @imap.disconnected?
      imap
    end

    def logout
       if @imap && !@imap.disconnected?
         imap.logout
         imap.disconnect
       end
     end

    private

    def connect
      @imap = Net::IMAP.new(options[:host], options[:port], options[:use_ssl])
      @imap.login(options[:username], options[:password])
    end

    def imap
      @imap
    end

    def options
      @options
    end
  end
end
