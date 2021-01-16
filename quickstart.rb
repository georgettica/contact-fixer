# pulled from https://developers.google.com/people/quickstart/ruby
# modified a bit to run my code and be 


require 'highline'

require "fileutils"

require "google/apis/people_v1"
require "googleauth"
require "googleauth/stores/file_token_store"

require_relative 'lib/contact_fixer'

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Google People API Ruby Quickstart".freeze
CREDENTIALS_PATH = "secrets/credentials.json".freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = "secrets/token.yaml".freeze
SCOPE = Google::Apis::PeopleV1::AUTH_CONTACTS

TIMEOUT_BETWEEN_UPLOAD_REQUESTS_IN_SECONDS = 2

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
  user_id = "default"
  credentials = authorizer.get_credentials user_id
  if credentials.nil?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

##
# initialize the service with all of the constant data provided above
#
# @ return [Google::Apis::PeopleV1::PeopleServiceService] functioning PeopleService
def init_service
  # Initialize the API
  service = Google::Apis::PeopleV1::PeopleServiceService.new
  service.client_options.application_name = APPLICATION_NAME
  service.authorization = authorize
  service
end

##
# Uploads contacts with updated phone numbers to google contacts list.
#
def upload_contacts(contacts, contact_fixer, cli)
  cli.say("Uploading the updated connections phone numbers.")
  contacts.each do |contact|
    contact_fixer.upload_connection_data(contact)
    # Adding a time gap between sent requests in order to avoid requests overload.
    sleep(TIMEOUT_BETWEEN_UPLOAD_REQUESTS_IN_SECONDS)
  end
end

contact_fixer = ContactFixer.new(init_service, $stdout)
all_contacts = contact_fixer.get_all_contacts

cli = HighLine.new

raw_filter = cli.ask("What filter do you want ot run?  ") { |q| q.default = "[\+|0-9][0-9|\s|\\-|a-z|A-Z]*" }

contact_fixer = ContactFixer.new(init_service, $stdout, raw_filter)
all_contacts = contact_fixer.get_all_contacts

replacement_pattern = cli.ask("Choose replacement pattern (optional)  ") { |q| q.default = "\\0" }

puts "\nFiltering contacts with the chosen filter.\n\n"

output = contact_fixer.get_contacts_by_phone_filter(all_contacts, raw_filter)

output.each do |contact|
  contact_fixer.print_connection(contact)
end

puts "Updating connections numbers according to the given filter and replacement pattern.\n\n"

contact_fixer.update_connections_phone_numbers(output, replacement_pattern)

output.each do |contact|
  contact_fixer.print_connection(contact)
end

cli.choose do |menu|
  menu.prompt = "Do you wish to upload the changes?"
  menu.choice(:Yes) { upload_contacts(output, contact_fixer, cli) }
  menu.choices(:No) { cli.say("Have a nice day :)") }
end
