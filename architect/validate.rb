# get all Sender Authentications and validate any invalid ones
# Promts for a MAKO token 
require 'httparty'

# Get auth Token

puts "Please enter MAKO auth Token: "
token = gets.chomp
limit = 100
offset = limit
toval = 0
# Get all domain auths

puts "Validating Domain Authentications."
j = 0
validate_array = Array.new
response = HTTParty.get("https://api.sendgrid.com/v3/whitelabel/domains?limit=#{limit}&offset=#{offset - offset}", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
while (JSON.parse(response.to_s).count > 0) do
# response code
	response_code = response.code.to_s
	#puts "'#{response_code}'"
	response_json = JSON.parse(response.to_s)
	#puts response_json.count
	i=0
	while (i < response_json.count) do
		id = response_json[i]["id"]
		valid = response_json[i]["valid"]
		# puts "#{id} - #{valid}" 
		# Determine auths to validate
		if (valid === false)
			validate_array.push(id)
		end
		i = i+1
	end
	response = HTTParty.get("https://api.sendgrid.com/v3/whitelabel/domains?limit=#{limit}&offset=#{offset + (offset * j)}", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	if (response.headers['x-ratelimit-remaining'] == "0")
        puts "hitting rate limit, sleeping for a few seconds, until #{response.headers['x-ratelimit-reset']}"
        sleep(1) until Time.now.to_i >= response.headers['x-ratelimit-reset'].to_i
    end
	j = j + 1
end
# validate 
i = 0
while (i < validate_array.count) do
	response = HTTParty.post("https://api.sendgrid.com/v3/whitelabel/domains/#{validate_array[i]}/validate", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	if (response.headers['x-ratelimit-remaining'] == "0")
	    puts "hitting rate limit, sleeping for a few seconds, until #{response.headers['x-ratelimit-reset']}"
	    sleep(1) until Time.now.to_i >= response.headers['x-ratelimit-reset'].to_i
	end
	response_json = JSON.parse(response.to_s)
	if (response_json["valid"] == true)
		puts "Domain Authentication ID #{validate_array[i]} validated sucessfully."
	end
	if (response_json["valid"] == false)
		puts "Domain Authentication ID #{validate_array[i]} not able to validate. Errors: "
		puts "#{response_json["validation_results"]}"
		toval = toval + 1
	end
	i = i + 1
end

# Get all Link Branding

puts "Validating Link Branding."
j = 0
validate_array.clear
response = HTTParty.get("https://api.sendgrid.com/v3/whitelabel/links?limit=#{limit}&offset=#{offset - offset}", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
while (JSON.parse(response.to_s).count > 0) do
# response code
	response_code = response.code.to_s
	#puts "'#{response_code}'"
	response_json = JSON.parse(response.to_s)
	#puts response_json.count
	i=0
	while (i < response_json.count) do
		id = response_json[i]["id"]
		valid = response_json[i]["valid"]
		# puts "#{id} - #{valid}" 
		# Determine auths to validate
		if (valid === false)
			validate_array.push(id)
		end
		i = i+1
	end
	response = HTTParty.get("https://api.sendgrid.com/v3/whitelabel/links?limit=#{limit}&offset=#{offset + (offset * j)}", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	if (response.headers['x-ratelimit-remaining'] == "0")
        puts "hitting rate limit, sleeping for a few seconds, until #{response.headers['x-ratelimit-reset']}"
        sleep(1) until Time.now.to_i >= response.headers['x-ratelimit-reset'].to_i
    end
	j = j + 1
end
# validate 
i = 0
while (i < validate_array.count) do
	response = HTTParty.post("https://api.sendgrid.com/v3/whitelabel/links/#{validate_array[i]}/validate", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	if (response.headers['x-ratelimit-remaining'] == "0")
	    puts "hitting rate limit, sleeping for a few seconds, until #{response.headers['x-ratelimit-reset']}"
	    sleep(1) until Time.now.to_i >= response.headers['x-ratelimit-reset'].to_i
	end
	response_json = JSON.parse(response.to_s)
	if (response_json["valid"] == true)
		puts "Link Branding ID #{validate_array[i]} validated sucessfully."
	end
	if (response_json["valid"] == false)
		puts "Link Branding ID #{validate_array[i]} not able to validate. Errors: "
		puts "#{response_json["validation_results"]}"
		toval = toval + 1
	end
	i = i + 1
end

# Get all rDNS

puts "Validating rDNS."
j = 0
validate_array.clear
response = HTTParty.get("https://api.sendgrid.com/v3/whitelabel/ips?limit=#{limit}&offset=#{offset - offset}", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
while (JSON.parse(response.to_s).count > 0) do
# response code
	response_code = response.code.to_s
	#puts "'#{response_code}'"
	response_json = JSON.parse(response.to_s)
	#puts response_json.count
	i=0
	while (i < response_json.count) do
		id = response_json[i]["id"]
		valid = response_json[i]["valid"]
		# puts "#{id} - #{valid}" 
		# Determine auths to validate
		if (valid === false)
			validate_array.push(id)
		end
		i = i+1
	end
	response = HTTParty.get("https://api.sendgrid.com/v3/whitelabel/ips?limit=#{limit}&offset=#{offset + (offset * j)}", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	if (response.headers['x-ratelimit-remaining'] == "0")
        puts "hitting rate limit, sleeping for a few seconds, until #{response.headers['x-ratelimit-reset']}"
        sleep(1) until Time.now.to_i >= response.headers['x-ratelimit-reset'].to_i
    end
	j = j + 1
end
# validate 
i = 0
while (i < validate_array.count) do
	response = HTTParty.post("https://api.sendgrid.com/v3/whitelabel/ips/#{validate_array[i]}/validate", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	if (response.headers['x-ratelimit-remaining'] == "0")
	    puts "hitting rate limit, sleeping for a few seconds, until #{response.headers['x-ratelimit-reset']}"
	    sleep(1) until Time.now.to_i >= response.headers['x-ratelimit-reset'].to_i
	end
	response_json = JSON.parse(response.to_s)
	if (response_json["valid"] == true)
		puts "rDNS ID #{validate_array[i]} validated sucessfully."
	end
	if (response_json["valid"] == false)
		puts "rDNS ID #{validate_array[i]} not able to validate. Errors: "
		puts "#{response_json["validation_results"]}"
		toval = toval + 1
	end
	i = i + 1
end

puts "Script completed. #{toval} authentications failed to validate."
