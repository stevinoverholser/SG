#!/usr/bin/env ruby
# cron to create dummy validation data
# add execuable permissions
# Run as a Bash script (cronbash.sh) 
# crontab -e
# 00 09 * * 1-5 /Users/soverholser/Documents/Scripts/cronbash.sh
require 'httparty'
emails = [<<Add Random Array of emails as strings>>]
size = rand(100..500) #random sample range
test_data = emails.sample(size)
token = "<<api_key>>"
i=0
while (i <= size) do
	payload = "{\"email\": \"#{test_data[i]}\"}"
    response1 = HTTParty.post("https://api.sendgrid.com/v3/validations/email", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
    puts "#{i}/#{size} - #{response1.code}"
	if response1.headers['x-ratelimit-remaining'] == "0"
	    puts "hitting rate limit, sleeping for a few seconds"
	    sleep(1) until Time.now.to_i >= response1.headers['x-ratelimit-reset'].to_i
	    response1 = HTTParty.post("https://api.sendgrid.com/v3/validations/email", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
	end
	i = i + 1
end
