require 'contact_fixer'
require 'stringio'
require 'google/apis/people_v1'

PHONE_NUMBERS_RAW_FILTER = "976"
PHONE_NUMBERS_FILTER = Regexp.new PHONE_NUMBERS_RAW_FILTER
CONTACT_PHONE_NUMBER_POSTFIX = "-shoe"
CONTACT_PHONE_NUMBER = PHONE_NUMBERS_RAW_FILTER + CONTACT_PHONE_NUMBER_POSTFIX
HIGHLIGHTED_PHONE_NUMBER = PHONE_NUMBERS_RAW_FILTER.green + CONTACT_PHONE_NUMBER_POSTFIX

describe ContactFixer do
  before(:each) do
    @svc = instance_double("PeopleServiceService")
    @mock_phone_number = instance_double("phoneNumbers")
    @out = StringIO.new
    @cf = ContactFixer.new(@svc, @out)
  end

  describe '.print_connection_phone_numbers' do
    before(:each) do
      @cf_without_filter = ContactFixer.new(nil, @out)
      @cf_with_filter = ContactFixer.new(nil, @out, PHONE_NUMBERS_FILTER)
    end
    context 'received conntection phone numbers with non defined filter' do
      it 'should print the contact phone numbers' do
        # Arrange
        allow(@mock_phone_number).to receive(:value).and_return(CONTACT_PHONE_NUMBER)
        # Act
        @cf_without_filter.print_connection_phone_numbers([@mock_phone_number])
        # Assert
        expect(@out.string).to include(CONTACT_PHONE_NUMBER)
      end
    end
    context 'received conntection phone numbers with defined filter' do
      it 'should print the contact phone numbers with the filtered parts highlighted' do
        # Arrange
        allow(@mock_phone_number).to receive(:value).and_return(CONTACT_PHONE_NUMBER)
        # Act
        @cf_with_filter.print_connection_phone_numbers([@mock_phone_number])
        # Assert
        expect(@out.string).to include(HIGHLIGHTED_PHONE_NUMBER)
      end
    end
  end

  describe '.get_all_contacts' do
    context 'when there are no contacts' do
      it 'prints an empty result' do
        # Arrange
        @svc = instance_double("PeopleServiceService", :list_person_connections => [])
        @cf = ContactFixer.new(@svc, @out)
        # Act and assert
        expect(@cf.get_all_contacts).to eq([])
      end
    end
    context 'when there is one contact' do
      context 'and he has no fields' do
        it 'print an empty user' do
          # Arrange
          person = Google::Apis::PeopleV1::Person::new
          @svc = instance_double("PeopleServiceService", :list_person_connections => [person])
          @cf = ContactFixer.new(@svc, @out)
          # Act and assert
          expect(@cf.get_all_contacts).to eq([person])
        end
      end
    end
  end
  describe '.print_connections' do
    context 'he has only an email address' do
      it 'prints the user with the email' do
        # Arrange
        expected_email = "a@a.com"
        mock_email = instance_double("EmailAddress")
        allow(mock_email).to receive(:value).and_return(expected_email)
        person = instance_double("Person", :names => [], :phone_numbers => [], :email_addresses => [mock_email])
        allow(@svc).to receive_message_chain(:list_person_connections, :connections) {[person]}
        # Act
        @cf.print_connections(@cf.get_all_contacts)
        # Assert
        expect(@out.string).to include(expected_email)
      end
    end
    context 'he has only a phone number' do
      it 'prints the user with the phone number' do
        # Arrange
        expected_phone_number = "+9721234567"
        mock_phone_number = instance_double("phoneNumbers")
        allow(mock_phone_number).to receive(:value).and_return(expected_phone_number)
        person = instance_double("Person", :names => [], :phone_numbers => [mock_phone_number], :email_addresses => [])
        allow(@svc).to receive_message_chain(:list_person_connections, :connections) {[person]}
        # Act
        @cf.print_connections(@cf.get_all_contacts)
        # Assert
        expect(@out.string).to include(expected_phone_number)
      end
    end
    context 'he has only a name' do
      it 'prints the user with the name' do
        # Arrange
        expected_name = "Al Bundy"
        mock_name = instance_double("names")
        allow(mock_name).to receive(:display_name).and_return(expected_name)
        person = instance_double("Person", :names => [mock_name], :phone_numbers => [], :email_addresses => [])
        allow(@svc).to receive_message_chain(:list_person_connections, :connections) {[person]}
        # Act
        @cf.print_connections(@cf.get_all_contacts)
        # Assert
        expect(@out.string).to include(expected_name)
      end
    end
    context 'he has a phone number and the print filter was defined' do
      it 'print the user with the highlighted phone number' do
        # Arrange
        svc = instance_double("PeopleServiceService")
        cf = ContactFixer.new(svc, @out, PHONE_NUMBERS_FILTER)
        allow(@mock_phone_number).to receive(:value).and_return(CONTACT_PHONE_NUMBER)
        person = instance_double("Person", :names => [], :phone_numbers => [@mock_phone_number], :email_addresses => [])
        allow(svc).to receive_message_chain(:list_person_connections, :connections) {[person]}
        # Act
        cf.print_connections(cf.get_all_contacts)
        # Assert
        expect(@out.string).to include(HIGHLIGHTED_PHONE_NUMBER)
      end
    end
  end

  describe '.get_contacts_by_phone_filter' do
    before(:each) do
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
       allow(@fake_number).to receive(:value).and_return(CONTACT_PHONE_NUMBER)
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
    end
    context 'no contacts exist' do
      it 'should return an empty collection' do
        # Arrange
        @cf = ContactFixer.new(nil, @out, '')
        connections = []
        # Act and assert
        expect(@cf.update_connections_phone_numbers(connections, @replacement_pattern)).to eq([])
      end
    end
    context 'contact exists and has no phone numbers' do
      it 'should return the given connections collection' do
        # Arrange
        @cf = ContactFixer.new(nil, @out, '')
        fake_person = instance_double('Person', :phone_numbers => [])
        connections = [fake_person]
        # Act and assert
        expect(@cf.update_connections_phone_numbers(connections, @replacement_pattern)).to eq(connections)
      end
    end
    context 'contact exists with number and filter matches' do
      it 'should return the contact with the updated number' do
        # Arrange
        @cf = ContactFixer.new(nil, @out, '3$')
        expected_number = "0118-999-881-999-119-725-123"
        expect(@fake_number).to receive(:value).and_return(@contact_number, expected_number)
        allow(@fake_number).to receive(:value=).with(expected_number)
        fake_person = instance_double('Person', :phone_numbers => [@fake_number], :names => [], :email_addresses => [])
        connections = [fake_person]
        # Act
        @cf.update_connections_phone_numbers(connections, @replacement_pattern)
        # Assert
        @cf.print_connection(fake_person)
        expect(@out.string).to include(expected_number)
      end
    end
  end
  describe '.upload_connection_data' do
    context 'receives contact data' do
      it 'should send an update request' do
        # Arrange
        person_resource_name = "people/id452"
        @fake_number = instance_double("PhoneNumber")
        fake_person = instance_double('Person', :phone_numbers => [@fake_number], :resource_name => person_resource_name)
        # Act and assert
        expect(@svc).to receive(:update_person_contact).with(person_resource_name, fake_person, {:update_person_fields => CONTACTS_PHONE_NUMBERS_FIELD_NAME})
        @cf.upload_connection_data(fake_person)
      end
    end
  end
end
