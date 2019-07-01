# tne_designs.rb
=begin 

Download 'COPY AS JSON' bundle for Sequel Pro (https://sequelpro.com/docs/bundles/how-to)

Run Query:

	select name, 
	replace(replace(replace(replace(replace(html_content,"/","\\\/" ), "\t", "\\t"), "\r", "\\r"),"\n","\\n"),CHAR(3),"") as "html_content",
	replace(replace(replace(replace(replace(plain_content,"/","\\\/" ), "\t", "\\t"), "\r", "\\r"),"\n","\\n"),CHAR(3),"")  as "plain_content", 
	case when editor_id = 1 then "design" else "code" end as "editor"
	from marketing_template where user_id={UID}

Select all > Bundles > Copy > Copy as JSON

Check JSON syntax in JSONLint

Save as a JSON input file

CALL FUNCTION WITH 2 ARGUMENTS:
						1			  2
ruby tne_design.rb input.json {MAKO_AUTH_TOKEN}

=end

require 'httparty'
require 'json'
require 'csv'

json_source_file = ARGV[0].to_s
token = ARGV[1].to_s
data = String.new.tap do |x|
File.open(json_source_file) { |f|  x << f.read }
end

input = JSON.parse(data)

headers = "\"Authorization\" => \"token #{token}\", \"Content-Type\" => \"application/json\""

i = 0
while (i < input["data"].count) do
	payload = input["data"][i].to_json
	puts "creating TNE template for #{input["data"][i]["name"]}"
	#puts payload

	response = HTTParty.post("https://api.sendgrid.com/v3/designs", body: payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	if (response.headers['x-ratelimit-remaining'] == "0")
	    puts "hitting rate limit, sleeping for a few seconds, until #{response.headers['x-ratelimit-reset']}"
	    sleep(1) until Time.now.to_i >= response.headers['x-ratelimit-reset'].to_i
	end
	if (response.code == 201)
		puts "Success"						
	else
		puts "ERROR: \n #{response.code} - #{response}"
	end

 #puts payload
 i = i + 1
end
