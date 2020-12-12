class ContactFixer
  def initialize(contacts_api, output)
    @contacts_api = contacts_api
    @output = output
  end

  def print_connections(response)
    @output.puts "Connection names:"
    @output.puts "No connections found" if response.connections.empty?
    response.connections.each do |person|
      names = person.names
      if names.nil?
        @output.puts "No names found for connection"
      else
        @output.puts names.map { |name| name.display_name }.inspect
      end
      phone_numbers = person.phone_numbers
      if phone_numbers.nil?
        @output.puts "No numbers found for connection"
      else
        @output.puts "- " + phone_numbers.map { |phone_number| phone_number.value }.inspect
      end
    end
  end

  def get_all_contacts
    @contacts_api.list_person_connections(
      "people/me",
    #  page_size:     10, # not used as I need all of the contacts
      person_fields: "names,phoneNumbers"
    )
  end

end
