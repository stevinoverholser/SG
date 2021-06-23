# verify.rb - Twilio verify test
require 'httparty'
require 'json'
require 'rubygems'
require 'twilio-ruby'
verified_flag = 0
validate_flag = 0

####Email Validation####
token = "<<apikey>>"
while (validate_flag == 0)
    puts "Enter email address:"
    email = gets.chomp
    payload = "{\"email\": \"#{email}\"}"
    response1 = HTTParty.post("https://api.sendgrid.com/v3/validations/email", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
    if response1.headers['x-ratelimit-remaining'] == "0"
        puts "hitting rate limit, sleeping for a few seconds"
        sleep(1) until Time.now.to_i >= response1.headers['x-ratelimit-reset'].to_i
        response1 = HTTParty.post("https://api.sendgrid.com/v3/validations/email", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
    end
    if response1["result"]["suggestion"]
        puts "Try again, maybe you meant #{response1["result"]["suggestion"]}"
    else
        validate_flag = 1
    end
end

####Number Verification####
@client = Twilio::REST::Client.new('ACXXXXX', 'XXXXX')
verification = @client.verify
                      .services('VAXXXX')
                      .verifications
                      .create(to: "#{email}", channel: 'email')

puts verification.sid
while (verified_flag == 0)
    puts "Enter code:"
    code = gets.chomp
    verification_check = @client.verify
                                .services('VAXXXX')
                                .verification_checks
                                .create(to: "#{email}", code: "#{code}")


    if  verification_check.status != "approved"
        puts "verification status is #{verification_check.status}, try again:"
    else                               
        verified_flag = 1
    end
end
puts verification_check.status
