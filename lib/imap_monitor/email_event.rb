module ImapMonitor
  module EmailEvent
    module Observer
      def property_changed(clazz, property, value)
        nil
      end
    end

    module Observable
      def register(object)
        listeners << object unless listeners.include?(object)
      end

      def deregister(object)
        listeners.delete(object)
      end

      def listeners
        @listeners ||= []
      end

      def fire_change(property, value)
        listeners.each do |listener|
          if listener.respond_to?(:property_changed)
            listener.property_changed(self.class.name, property, value)
          end
        end
      end
    end
  end
end
