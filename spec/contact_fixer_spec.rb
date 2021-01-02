require 'contact_fixer'
require 'stringio'
require 'google/apis/people_v1'

describe ContactFixer do
  before(:each) do
    @svc = instance_double("PeopleServiceService")
    @out = StringIO.new
    @cf = ContactFixer.new(@svc, @out)
  end

  describe '.get_all_contacts' do
    context 'when there are no contacts' do
      it 'prints an empty result' do
        @svc = instance_double("PeopleServiceService", :list_person_connections => [])
        @cf = ContactFixer.new(@svc, @out)
        expect(@cf.get_all_contacts).to eq([])
      end
    end
    context 'when there is one contact' do
      context 'and he has no fields' do
        it 'print an empty user' do
          person = Google::Apis::PeopleV1::Person::new
          @svc = instance_double("PeopleServiceService", :list_person_connections => [person])
          @cf = ContactFixer.new(@svc, @out)
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
  end

  describe '.get_contacts_by_phone_filter' do
    before(:each) do
      @contact_number = "976-shoe"
      @fake_number = instance_double("PhoneNumber")
      @cf = ContactFixer.new(nil, @out)
    end
    context 'no contacts exist' do
      it 'should print an empty result' do
       fake_connections = instance_double('Connections', :connections => [])
       expect(@cf.get_contacts_by_phone_filter(fake_connections,'')).to eq([])
      end
    end
    context 'contact exists and has no phone numbers' do
      it 'should print an empty result' do
       fake_person = instance_double('Person', :phone_numbers => [])
       fake_connections = instance_double('Connections', :connections => [fake_person])
       expect(@cf.get_contacts_by_phone_filter(fake_connections,'')).to eq([])
      end
    end
    context 'contact exists with number and filter is empty' do
      it 'should print an empty result' do
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
       expect(@cf.get_contacts_by_phone_filter(fake_connections,"^.{0}$")).to eq([])
      end
    end
  end
end
