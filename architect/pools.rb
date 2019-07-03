# Create pools and add IPs on user

#expects ARGV[0] of input file:
#EXAMPLE:
=begin e
{
 "token" : "MAKO",	
 "pools": [
    {
      "name": "HIGH",
      "ips": ["149.72.170.86","167.89.21.107"]
    },
    {
      "name": "LOW",
      "ips": ["168.245.20.151","168.245.60.69"]
    }
  ]
}
=end

# Where "token" is a MAKO token

require 'httparty'
require 'json'

json_source_file = ARGV[0].to_s

data = String.new.tap do |x|
File.open(json_source_file) { |f|  x << f.read }
end

input = JSON.parse(data)
token = input["token"]

@pool_array = Array.new
input["pools"].each { |pool| @pool_array << OpenStruct.new(pool) }

@pool_array.each do |pool|
	# create pool
	create_pool_uri = "https://api.sendgrid.com/v3/ips/pools"
	payload = "{\"name\": \"#{pool.name}\"}"
	response = HTTParty.post(create_pool_uri, body: payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	# response code
	response_code = response.code.to_s
	puts "'#{response_code}' - #{response}"
	# add IPs to pool
	
	pool["ips"].each do |ips|
		add_ip_uri = "https://api.sendgrid.com/v3/ips/pools/#{pool.name}/ips"
		payload = "{\"ip\": \"#{ips}\"}"
		response = HTTParty.post(add_ip_uri, body: payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
		# response code
		response_code = response.code.to_s
		if response.headers['x-ratelimit-remaining'] == "0"
	       puts "hitting rate limit, sleeping for a few seconds, until #{response.headers['x-ratelimit-reset']}"
	       sleep(1) until Time.now.to_i >= response.headers['x-ratelimit-reset'].to_i
	    end
	    if response.code == 404
	    	# handle is IP is not active on parent
	    	# get subuser this IP is assigned too
	    	response = HTTParty.get("https://api.sendgrid.com/v3/ips/#{ips}", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	    	response_json = JSON.parse(response.to_s)
	    	#puts response_json
	    	subuser_array = response_json["subusers"]
	    	# get parent username
	    	response = HTTParty.get("https://api.sendgrid.com/v3/user/username", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	    	response_json = JSON.parse(response.to_s)
	    	username = response_json["username"]
	    	subuser_array = subuser_array.push(username)
	    	#puts "HERE #{subuser_array}"
	    	#Assign IP to parent
	    	response = HTTParty.put("https://api.sendgrid.com/v3/ips/#{ips}", body: "{\"subusers\": #{subuser_array}, \"warmup\" : false }" , headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	    	#add IP to pool
	    	response = HTTParty.post(add_ip_uri, body: payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	    	subuser_array.pop
	    	#puts "https://api.sendgrid.com/v3/ips/#{ips} - {\"subusers\": #{subuser_array}, \"warmup\" : false }"
	    	#remove IP from parent
	    	response = HTTParty.put("https://api.sendgrid.com/v3/ips/#{ips}", body: "{\"subusers\": #{subuser_array}, \"warmup\" : false }" , headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	    end
		#puts "'#{response_code}' - #{response}"

	end
end
