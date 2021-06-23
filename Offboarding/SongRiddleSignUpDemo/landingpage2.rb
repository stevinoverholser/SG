require 'rubygems'
require 'twilio-ruby'
require 'sinatra'
require 'httparty'
require 'cgi'


emailsyntax = "p1"
numbersyntax = "p1"

#./ngrok http 4567
#Setting port
#set :port, 53
set :bind, '0.0.0.0'
#
get '/' do
	#erb :webpage
	erb :webpage2, :locals => {:emailsyntax => emailsyntax, :numbersyntax => numbersyntax}
end

get '/action_page' do
	# Email validation
	payload = "{\"email\": \"#{params['email']}\"}"
  	response1 = HTTParty.post("https://api.sendgrid.com/v3/validations/email", body: payload, headers: {"Authorization" => "Bearer <<apikey>>", "Content-Type" => "application/json"})
  	if response1.headers['x-ratelimit-remaining'] == "0"
    	puts "hitting rate limit, sleeping for a few seconds"
    	sleep(1) until Time.now.to_i >= response1.headers['x-ratelimit-reset'].to_i
    	response1 = HTTParty.post("https://api.sendgrid.com/v3/validations/email", body: payload, headers: {"Authorization" => "Bearer <<apikey>>", "Content-Type" => "application/json"})
  	end
  	puts response1
  	knownbounce = response1["result"]["checks"]["additional"]["has_known_bounces"]
  	local = response1["result"]["local"]
  	##### EMAIL AND PHONE NUMBER SYNTAX VALIDATION ####
  	if (response1["result"]["checks"]["domain"]["has_valid_address_syntax"] == false)
  		emailsyntax = "p"
  		redirect to ('/')
  	else
  		emailsyntax = "p1"

  	end
  	if !(params['phone'].match(/^\d{10}$/))
  		numbersyntax = "p"
  		redirect to ('/')
  	else
  		numbersyntax = "p1"
  	end
  	# Phone number validation
  	account_sid = 'ACXXX'
	auth_token = 'XXXX'
	@client = Twilio::REST::Client.new(account_sid, auth_token)
	phone_number = @client.lookups
                      .phone_numbers("+1#{params['phone']}")
                      .fetch(type: ['carrier'])
	puts phone_number.carrier["type"]
	landline = phone_number.carrier["type"]

	

  	if !(response1["result"].has_key? 'suggestion')
  		query = params.map{|key, value| "#{key}=#{value}"}.join("&")
  		#redirect to("/success?#{query}")
  		redirect to("/success?kb=#{knownbounce}&ll=#{landline}&#{query}")
	else
		#raise MyCustomError, 'something bad'
=begin
		code = "<form action=\"/success\">
		You entered <%= params['email'] %> did you mean #{local}@#{response1["result"]["suggestion"]}? <br>
		<input name=\"kb\" value=\"#{knownbounce}\" hidden/>
		<input name=\"ll\" value=\"#{landline}\" hidden/>
  		<input name=\"fname\" value=\"<%= params['fname'] %>\" hidden/>
		<input name=\"lname\" value=\"<%= params['lname'] %>\" hidden/>
		<input type=\"radio\" name=\"email\" value=\"<%= params['email'] %>\" checked> No, continue with entered email address <br>
  		<input type=\"radio\" name=\"email\" value=\"#{local}@#{response1["result"]["suggestion"]}\" checked> Yes, I meant #{local}@#{response1["result"]["suggestion"]} <br>
		<input name=\"phone\" value=\"<%= params['phone'] %>\" hidden/>
		<input name=\"contact\" value=\"<%= params['contact'] %>\" hidden/>
  		<input type=\"submit\" value=\"Submit\">
  		</form>"
  		erb code
=end
	erb :bad, :locals => {:email => params['email'], :knownbounce => knownbounce, :landline => landline, :fname => params['fname'], :lname => params['lname'], :local => local, :suggestion =>response1["result"]["suggestion"], :phone =>params['phone'], :contact =>params['contact']  }
	end
	#redirect to('/success')

end
get '/success' do
	#code = "<p>Thanks For your intrest #{params['fname']}, we will be in touch soon!</p>"
	#erb code
fname = params['fname']
lname = params['lname']
email = params['email']
phone = params['phone']
contact = params['contact']
if params['kb'] == "true"
	knownbounce = "true"
else
	knownbounce = "false"
end
if params['ll'] == "landline"
landline = "true"
else
landline = "false"
end
puts fname
puts lname
puts email
puts phone
puts contact
puts landline
puts knownbounce
parameters = "{\"email\": \"#{email}\", \"fname\": \"#{fname}\", \"lname\": \"#{lname}\", \"phone\": \"+1#{phone}\", \"contact\": \"#{contact}\", \"knownbounce\": \"#{knownbounce}\", \"landline\": \"#{landline}\"}" 
puts parameters
response3 = HTTParty.post("https://ACXXX:XXXX@studio.twilio.com/v1/Flows/FW2490bc2ac76c0234d79a4d9a0174e408/Executions", body: {To: "+13037464124", From: "+17205730108", Parameters: parameters})
puts response3 
erb :success, :locals => { :fname => fname}
end
