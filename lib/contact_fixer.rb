MAXIMUM_NUMBER_OF_DISPLAYED_CONTACTS = 1000
CONTACTS_NAMES_FIELD_NAME = "names"
CONTACTS_PHONE_NUMBERS_FIELD_NAME = "phoneNumbers"
CONTACTS_EMAIL_ADDRESSES_FIELD_NAME = "emailAddresses"

NO_CONNECTIONS_SEARCH_MESSAGE = "No connections found"

require 'colorize'

class ContactFixer
  def initialize(contacts_api, output, raw_filter = nil)
    @filter = nil
    unless raw_filter.nil?
      @filter = Regexp.new raw_filter
    end
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

  def print_connection_phone_numbers(phone_numbers)
    displayed_phone_numbers = "- " + phone_numbers.map { |phone_number| phone_number.value }.inspect
    if @filter.nil?
      @output.puts displayed_phone_numbers
    else
      @output.puts displayed_phone_numbers.gsub(@filter) {|number| number.green}
    end
  end

  def print_connection(person)
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
      print_connection_phone_numbers(phone_numbers)
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

  def upload_connection_data(person)
    @contacts_api.update_person_contact(
      person.resource_name,
      person,
      update_person_fields: CONTACTS_PHONE_NUMBERS_FIELD_NAME
    )
  end

  def update_connections_phone_numbers(connections, substitute_pattern)
    @output.puts NO_CONNECTIONS_SEARCH_MESSAGE if connections.empty?
    different_connections = connections.select do |person|
      person.phone_numbers&.any? do |phone_number|  
        number_after_replacement = phone_number.value.gsub(@filter, substitute_pattern)
        phone_number.value != number_after_replacement
      end
    end

    res = different_connections.each do |person|
      person.phone_numbers&.each do |phone_number|
        phone_number.value.gsub!(@filter, substitute_pattern)
      end
    end
    res
  end

  def get_contacts_by_phone_filter(contacts, raw_filter)
    @filter = Regexp.new raw_filter
    @output.puts NO_CONNECTIONS_SEARCH_MESSAGE if contacts.connections.empty?
    contacts.connections.select do |person|
      person.phone_numbers&.any? { |phone_number| phone_number.value.match(@filter) }
    end
  end

  def get_all_contacts
    @contacts_api.list_person_connections(
      "people/me",
      page_size: MAXIMUM_NUMBER_OF_DISPLAYED_CONTACTS,
      person_fields: [CONTACTS_NAMES_FIELD_NAME, CONTACTS_PHONE_NUMBERS_FIELD_NAME, CONTACTS_EMAIL_ADDRESSES_FIELD_NAME].join(',')
    )
  end

end
