require 'contact_fixer'
require 'stringio'
require 'google/apis/people_v1'

describe ContactFixer do
  before(:each) do
    @out = StringIO.new
  end

  describe '.get_all_contacts' do
    before(:each) do
      @contact_phone_number = "+9721234567"
    end
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
    context 'he has a phone number and the print filter was defined' do
      it 'print the user with the highlighted phone number' do
        # Arrange
        expected_phone_number = "+972".green + "1234567"
        mock_phone_number = instance_double("phoneNumbers")
        allow(mock_phone_number).to receive(:value).and_return(@contact_phone_number)
        person = instance_double("Person", :names => [], :phone_numbers => [mock_phone_number], :email_addresses => [])
        svc = instance_double("PeopleServiceService")
        allow(@svc).to receive_message_chain(:list_person_connections, :connections) {[person]}
        # Act
        cf = ContactFixer.new(svc, @out)
        cf.print_connections(cf.get_all_contacts, "\\+972")
        # Assert
        expect(@out.string).to include(expected_phone_number)
      end
    end
  end
end
