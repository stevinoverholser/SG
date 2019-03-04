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
		puts "'#{response_code}' - #{response}"

	end
end
