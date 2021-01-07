require 'colorize'

class ContactFixer
  def initialize(contacts_api, output)
    @contacts_api = contacts_api
    @output = output
  end

  # Added the method from the following discussion: https://www.ruby-forum.com/t/how-to-detect-if-a-string-contains-any-funny-characters-from-non-english-alphabets/143811/2
  # The method checks if the given string contains a non "Roman Alphabet" (A-Z) letters by iterating the string
  # and returning a positive result for the first letter that does not match the given regular expression.
  def self.is_non_roman(str)
    str =~ /[^\w\s!..]/
  end

  def get_fixed_display_name(display_name)
    if ContactFixer.is_non_roman(display_name)
      display_name.reverse
    else
      display_name
    end
  end

  def print_connection_phone_numbers(phone_numbers, raw_filter)
    if raw_filter.nil?
      @output.puts "- " + phone_numbers.map { |phone_number| phone_number.value }.inspect
    else
      filter = Regexp.new raw_filter
      @output.puts "- " + phone_numbers.map { |phone_number| phone_number.value }.inspect.gsub(filter) {|number| number.green}
    end
  end

  def print_connection(person, raw_filter = nil)
    names = person.names
    if names.nil?
      @output.puts "No names found for connection"
    else
      @output.puts names.map { |name| get_fixed_display_name(name.display_name) }.inspect
    end
    phone_numbers = person.phone_numbers
    if phone_numbers.nil?
      @output.puts "No numbers found for connection"
    else
      print_connection_phone_numbers(person, raw_filter)
    end
    emails = person.email_addresses
    if emails.nil?
      @output.puts "No emails found for connection"
    else
      @output.puts "- " + emails.map { |email| email.value }.inspect
    end
    # newline is always good
    @output.puts ""
  end

  def print_connections(response)
    @output.puts "Connection names:"
    @output.puts "No connections found" if response.connections.empty?
    response.connections.each do |person|
      print_connection(person)
    end
  end

  def get_contacts_by_phone_filter(contacts, raw_filter)
    filter = Regexp.new raw_filter
    @output.puts "No connections found" if contacts.connections.empty?
    contacts.connections.select do |person|
      phone_numbers = person.phone_numbers

      if phone_numbers.nil?
        false
      else
        phone_numbers.any? { |phone_number| phone_number.value.match(filter) }
      end
    end
  end

  def get_all_contacts
    @contacts_api.list_person_connections(
      "people/me",
    #  page_size:     10, # not used as I need all of the contacts
      person_fields: "names,phoneNumbers,emailAddresses"
    )
  end

end
