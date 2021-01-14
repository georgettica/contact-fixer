require 'contact_fixer'
require 'stringio'
require 'google/apis/people_v1'

describe ContactFixer do
  before(:each) do
    @out = StringIO.new
  end

  describe '.get_all_contacts' do
    context 'when there are no contacts' do
      it 'prints an empty result' do
        svc = instance_double("PeopleServiceService", :list_person_connections => [])
        cf = ContactFixer.new(svc, @out)
        expect(cf.get_all_contacts).to eq([])
      end
    end
    context 'when there is one contact' do
      context 'and he has no fields' do
        it 'print an empty user' do
          person = Google::Apis::PeopleV1::Person::new
          svc = instance_double("PeopleServiceService", :list_person_connections => [person])
          cf = ContactFixer.new(svc, @out)
          expect(cf.get_all_contacts).to eq([person])
        end
      end
      context 'he has only an email address' do
        it 'prints the user with the email' do
          # Arrange
          expected_email = "a@a.com"
          mock_email = instance_double("EmailAddress")
          allow(mock_email).to receive(:value).and_return(expected_email)
          person = instance_double("Person", :names => [], :phone_numbers => [], :email_addresses => [mock_email])
          svc = instance_double("PeopleServiceService")
          allow(svc).to receive_message_chain(:list_person_connections, :connections) {[person]}
          # Act
          cf = ContactFixer.new(svc, @out)
          cf.print_connections(cf.get_all_contacts)
          # Assert
          expect(@out.string).to include(expected_email)
        end
      end
    end
  end

  describe '.get_contacts_by_phone_filter' do
    before(:each) do
      @contact_number = "976-shoe"
      @fake_number = instance_double("PhoneNumber")
      @cf = ContactFixer.new(nil, @out)
    end
    context 'no contacts exist' do
      it 'should print an empty result' do
       # Arrange
       fake_connections = instance_double('Connections', :connections => [])
       # Act and assert
       expect(@cf.get_contacts_by_phone_filter(fake_connections,'')).to eq([])
      end
    end
    context 'contact exists and has no phone numbers' do
      it 'should print an empty result' do
       # Arrange
       fake_person = instance_double('Person', :phone_numbers => [])
       fake_connections = instance_double('Connections', :connections => [fake_person])
       # Act and assert
       expect(@cf.get_contacts_by_phone_filter(fake_connections,'')).to eq([])
      end
    end
    context 'contact exists with number and filter is empty' do
      it 'should print an empty result' do
       # Arrange
       allow(@fake_number).to receive(:value).and_return(@contact_number)
       fake_person = instance_double('Person', :phone_numbers => [@fake_number])
       fake_connections = instance_double('Connections', :connections => [fake_person])
       # Checks if the result does not contain characters between the start and the end of the line:
       # 1) '^' represents the beginning of the line and '$' represents the end of the line.
       # 2) .{0} represents a zero-length string - the '.' symbolize the characters that can appear in the string.
       # (every character except \n) and {d} defines the size of the string (size(str) = d).
       # 
       # This information is from the following guide: https://www.rubyguides.com/2015/06/ruby-regex/
       # under the sections 'Ranges', 'Modifiers' and 'Exact String Matching'.
       #
       # Act and assert
       expect(@cf.get_contacts_by_phone_filter(fake_connections,"^.{0}$")).to eq([])
      end
    end
  end
  describe '.update_connections_phone_numbers' do
    before(:each) do
      @replacement_pattern = '123'
      @contact_number = "0118-999-881-999-119-725-3"
      @fake_number = instance_double("PhoneNumber")
      @cf = ContactFixer.new(nil, @out)
    end
    context 'no contacts exist' do
      it 'should return an empty collection' do
        # Arrange
        connections = []
        # Act and assert
        expect(@cf.update_connections_phone_numbers(connections, '', @replacement_pattern)).to eq([])
      end
    end
    context 'contact exists and has no phone numbers' do
      it 'should return the given connections collection' do
        # Arrange
        fake_person = instance_double('Person', :phone_numbers => [])
        connections = [fake_person]
        # Act and assert
        expect(@cf.update_connections_phone_numbers(connections, '', @replacement_pattern)).to eq(connections)
      end
    end
    context 'contact exists with number and filter is invalid' do
      it 'should raise a regex expression error' do
        # Arrange
        allow(@fake_number).to receive(:value).and_return(@contact_number)
        fake_person = instance_double('Person', :phone_numbers => [@fake_number])
        connections = [fake_person]
        # Act and assert
        expect { @cf.update_connections_phone_numbers(connections, '*', @replacement_pattern) }.to raise_error(RegexpError)
      end
    end
    context 'contact exists with number and filter matches' do
      it 'should return the contact with the updated number' do
        # Arrange
        expected_number = "0118-999-881-999-119-725-123"
        expect(@fake_number).to receive(:value).and_return(@contact_number, expected_number)
        allow(@fake_number).to receive(:value=).with(expected_number)
        fake_person = instance_double('Person', :phone_numbers => [@fake_number], :names => [], :email_addresses => [])
        connections = [fake_person]
        # Act
        @cf.update_connections_phone_numbers(connections, '3$', @replacement_pattern)
        # Assert
        @cf.print_connection(fake_person)
        expect(@out.string).to include(expected_number)
      end
    end
  end
end