require 'spec_helper'

class TestMonitor
  include ImapMonitor::EmailEvent::Observable
end

class TestInterestedParty
  include ImapMonitor::EmailEvent::Observer

  def property_changed(clazz, prop, value)
    "1 class: #{clazz}, property: #{prop}, value: #{value}"
  end
end

class TestInterestedParty2
  include ImapMonitor::EmailEvent::Observer

  def property_changed(clazz, prop, value)
    "2 class: #{clazz}, property: #{prop}, value: #{value}"
  end
end

describe 'EmailEvent  ' do
  let(:master) { TestMonitor.new }
  let(:party_a) { TestInterestedParty.new }
  let(:party_b) { TestInterestedParty2.new }

  describe 'Observer' do
    describe '#property_changed' do
      before(:each) do
        master.register(party_a)
        master.register(party_b)
      end

      it 'calls the interested parties overridden method' do
        expect(master.listeners.
          first.property_changed('TestMonitor', :blah, 'mah')).
            to eq '1 class: TestMonitor, property: blah, value: mah'

        expect(master.listeners.
          last.property_changed('TestMonitor', :mah, 'blah')).
            to eq '2 class: TestMonitor, property: mah, value: blah'
      end
    end
  end

  describe 'Observable' do
    describe '#register' do
      it 'registers multiple interested observer' do
        master.register(party_a)
        expect(master.listeners).to eq [party_a]

        master.register(party_b)
        expect(master.listeners).to eq [party_a, party_b]
      end

      it 'doesnt register the same object twice' do
        master.register(party_a)
        master.register(party_b)

        expect(master.listeners).to eq [party_a, party_b]

        master.register(party_a)
        expect(master.listeners).to eq [party_a, party_b]
      end
    end

    describe '#deregister' do
      it 'removes the specific object from the register list' do
        master.register(party_a)
        master.register(party_b)

        expect(master.listeners).to eq [party_a, party_b]

        master.deregister(party_a)
        expect(master.listeners).to eq [party_b]
      end
    end

    describe '#listeners' do
      it 'returns an empty array when @listeners is nil' do
        expect(master.listeners).to eq []
      end

      it 'returns the registered observers' do
        master.register(party_a)
        master.register(party_b)

        expect(master.listeners).to eq [party_a, party_b]
      end
    end

    describe '#fire_change' do
      it 'doesnt error when there are no registered observers' do
        expect(party_a).to receive(:property_changed).exactly(0).times
        expect(party_b).to receive(:property_changed).exactly(0).times

        expect {
          master.fire_change(:EmailEvent, 'RFC822Email')
        }.not_to raise_error NoMethodError
      end

      it 'calls property_change when there is just one observer' do
        master.register(party_a)

        expect(party_a).to receive(:property_changed).once
        expect(party_b).to receive(:property_changed).exactly(0).times

        master.fire_change(:EmailEvent, 'RFC822Email')
      end

      it 'calls property_change on all registered observers' do
        master.register(party_a)
        master.register(party_b)

        expect(party_a).to receive(:property_changed).once
        expect(party_b).to receive(:property_changed).once

        master.fire_change(:EmailEvent, 'RFC822Email')
      end
    end
  end
end
