# Create pools and add IPs on user

#expects ARGV[0] of input file:
#EXAMPLE:
=begin 
{
 "token" : "MAKO",	
 "subusers": [
    {
      "username": "Subuser1",
      "ips": ["149.72.170.86","167.89.21.107"]
    },
    {
      "username": "Subuser2",
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

@subuser_array = Array.new
input["subusers"].each { |subuser| @subuser_array << OpenStruct.new(subuser) }
@subuser_array.each do |subuser|
#@subuser_array.each do |subuser|
	# PUT ip array to subuser
		payload = "{#{subuser.ips}}".sub("{","").sub("}","")
		uri = "https://api.sendgrid.com/v3/subusers/#{subuser.username}/ips"
		response = HTTParty.put(uri, body: payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
		# response code
		response_code = response.code.to_s
		puts "'#{response_code}' - #{response}"
end
