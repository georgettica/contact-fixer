require 'contact_fixer'
require 'stringio'

describe ContactFixer do
  describe '.get_all_contacts' do
    context 'when there are no contacts' do
      it 'prints an empty result' do
        out = StringIO.new
        svc = instance_double("PeopleServiceService", :list_person_connections => [])
        cf = ContactFixer.new(svc, out)
        expect(cf.get_all_contacts).to eq([])
      end
    end
  end
end
