#parse-sms.rb - convernt a parse into a SMS ex: 1234567890@parse.com
require 'rubygems'
require 'twilio-ruby'
require 'sinatra'
require 'httparty'
# ruby parse_to_sms.rb
# ./ngrok http 4567
# make NGROK URL parse webhook URL
post '/' do
	body = params['text']
	puts body
	to = params['to']
	to.slice! "@{PARSE_DOMAIN}"
	puts to
	account_sid = '{ACCOUNT_SID}'
	auth_token = '{AUTH_TOKEN}'
	@client = Twilio::REST::Client.new(account_sid, auth_token)
	message = @client.messages.create(
                             from: '{FROM_NUMBER}',
                             body: body,
                             to: to
                           )
	puts message.sid
end
