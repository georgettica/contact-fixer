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

contact_fixer = ContactFixer.new(init_service, $stdout)
all_contacts = contact_fixer.get_all_contacts
cli = HighLine.new


first_filter = cli.ask("What filter do you want ot run?  ") { |q| q.default = "[\+|0-9][0-9|\s|\\-|a-z|A-Z]*" }

output = contact_fixer.get_contacts_by_phone_filter(all_contacts, first_filter)

output.each do |contact|
  contact_fixer.print_connection(contact)
end
