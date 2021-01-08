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
       fake_connections = instance_double('Connections', :connections => [])
       expect(@cf.get_contacts_by_phone_filter(fake_connections, '')).to eq([])
      end
    end
    context 'contact exists and has no phone numbers' do
      it 'should print an empty result' do
       fake_person = instance_double('Person', :phone_numbers => [])
       fake_connections = instance_double('Connections', :connections => [fake_person])
       expect(@cf.get_contacts_by_phone_filter(fake_connections, '')).to eq([])
      end
    end
    context 'contact exists with number and filter is empty' do
      it 'should print an empty result' do
       allow(@fake_number).to receive(:value).and_return(@contact_number)
       fake_person = instance_double('Person', :phone_numbers => [@fake_number])
       fake_connections = instance_double('Connections', :connections => [fake_person])
       expect(@cf.get_contacts_by_phone_filter(fake_connections, '^.{0}$')).to eq([])
      end
    end
	context 'contact exists with number and filter matches' do
      it 'should print the contact details' do
       allow(@fake_number).to receive(:value).and_return(@contact_number)
       fake_person = instance_double('Person', :phone_numbers => [@fake_number])
       fake_connections = instance_double('Connections', :connections => [fake_person])
       expect(@cf.get_contacts_by_phone_filter(fake_connections, '976')).to eq([fake_person])
      end
    end
	context 'contact exists with number and filter is invalid' do
      it 'should raise a regex expression error' do
       allow(@fake_number).to receive(:value).and_return(@contact_number)
       fake_person = instance_double('Person', :phone_numbers => [@fake_number])
       fake_connections = instance_double('Connections', :connections => [fake_person])
	   expect { @cf.get_contacts_by_phone_filter(fake_connections, '*') }.to raise_error(RegexpError)
      end
    end
  end
end
