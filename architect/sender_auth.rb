# create Sender Authentications and produce user facing CSV

#expects ARGV[0] of input file:
#EXAMPLE:
=begin 
{
	"token": "Parent accounts MAKO token",
	"records": [
	{
		"mail_stream_name" : "used for CSV to provide to user",
		"username": "user this records should be created on",
		"domain" : "root/signing domain",
		"create_domain": "true or false",
		"domain_subdomain": "subdomain of domains",
		"automatic_security": "true or false",
		"default_domain": "true or false",
		"custom_dkim_selector": "value or false",
		"assign_domain_to_subuser": "username or false",
		"create_link": "true or false",
		"link_subdomain" : "subdomain for links",
		"default_link": "true or false",
		"assign_link_to_subuser": "username or false",
		"create_rdns": "true or false",
		"rdns_subdomain" : "subdomain for rdns",
		"ip": "IP to whitelabel or false"
	},
	{
	 	...Repeat as necessary...
	}
	]
}
=end

#### CHECK UNIQUE DOMAINS AND SUBDOMAINS

require 'httparty'
require 'json'
require 'csv'
json_source_file = ARGV[0].to_s

data = String.new.tap do |x|
File.open(json_source_file) { |f|  x << f.read }
end

input = JSON.parse(data)
token = input["token"]

headers = "\"Authorization\" => \"token #{token}\", \"Content-Type\" => \"application/json\""

i = 0
while (i < input["records"].count) do
	puts "Building authentications for '#{input["records"][i]["mail_stream_name"]}'"
	mail_stream_name = input["records"][i]["mail_stream_name"].to_s 
	if (mail_stream_name == "") 
		puts "No value for 'mail_stream_name'! Exiting." 
		exit 
	end
	username = input["records"][i]["username"].to_s
	if (username == "") 
		puts "No value for 'username'! Exiting." 
		exit 
	end
	domain_subdomain = input["records"][i]["domain_subdomain"].to_s
	if (domain_subdomain == "") 
		puts "No value for 'domain_subdomain'! Exiting." 
		exit 
	end
	domain = input["records"][i]["domain"].to_s
	if (domain == "") 
		puts "No value for 'domain'! Exiting." 
		exit 
	end
	create_domain = input["records"][i]["create_domain"].to_s
	if (create_domain == "") 
		puts "No value for 'create_domain'! Exiting." 
		exit 
	end
	automatic_security = input["records"][i]["automatic_security"].to_s
	if (automatic_security == "") 
		puts "No value for 'automatic_security'! Exiting." 
		exit 
	end
	default_domain = input["records"][i]["default_domain"].to_s
	if (default_domain == "") 
		puts "No value for 'default_domain'! Exiting." 
		exit 
	end
	custom_dkim_selector = input["records"][i]["custom_dkim_selector"].to_s
	if (custom_dkim_selector == "") 
		puts "No value for 'custom_dkim_selector'! Exiting." 
		exit 
	end
	assign_domain_to_subuser = input["records"][i]["assign_domain_to_subuser"].to_s
	if (assign_domain_to_subuser == "") 
		puts "No value for 'assign_domain_to_subuser'! Exiting." 
		exit 
	end
	create_link = input["records"][i]["create_link"].to_s
	if (create_link == "") 
		puts "No value for 'create_link'! Exiting." 
		exit 
	end
	link_subdomain = input["records"][i]["link_subdomain"].to_s
	if (link_subdomain == "") 
		puts "No value for 'link_subdomain'! Exiting." 
		exit 
	end
	rdns_subdomain = input["records"][i]["rdns_subdomain"].to_s
	if (rdns_subdomain == "") 
		puts "No value for 'rdns_subdomain'! Exiting." 
		exit 
	end
	default_link = input["records"][i]["default_link"].to_s
	if (default_link == "") 
		puts "No value for 'default_link'! Exiting." 
		exit 
	end
	assign_link_to_subuser = input["records"][i]["assign_link_to_subuser"].to_s
	if (assign_link_to_subuser == "") 
		puts "No value for 'assign_link_to_subuser'! Exiting." 
		exit 
	end
	create_rdns = input["records"][i]["create_rdns"].to_s
	if (create_rdns == "") 
		puts "No value for 'create_rdns'! Exiting." 
		exit 
	end
	ip = input["records"][i]["ip"].to_s
	if (ip == "") 
		puts "No value for 'ip'! Exiting." 
		exit 
	end

	domain_payload = "{\"domain\": \"#{domain}\", \"subdomain\": \"#{domain_subdomain}\""
	link_payload = "{\"domain\": \"#{domain}\", \"subdomain\": \"#{link_subdomain}\""
	rdns_payload = ""
	assign_to_sub_flag = false
	parent_flag = false
	# Check if user name is parent username

	response = HTTParty.get("https://api.sendgrid.com/v3/user/username", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	response_code = response.code.to_s
	if !(response_code == "200")
		puts "error creating '#{mail_stream_name}'"
		puts "'#{response_code}' - #{response}"
		exit
	end
	 parent_username = response["username"]
	if (parent_username == username)
		#set flag to check on API requests to not use on-behalf-of 
		parent_flag = true
	end

	if (create_domain == "true" || create_domain == "false")
		if (automatic_security == "true" || automatic_security == "false")
			if (default_domain == "true" || default_domain == "false")
				if (create_domain == "true")
					domain_payload = "#{domain_payload}, \"default\": #{default_domain}, \"automatic_security\": #{automatic_security}"
					if !(custom_dkim_selector == "false")
						domain_payload = "#{domain_payload}, \"custom_dkim_selector\": \"#{custom_dkim_selector}\""
					end
					domain_payload = "#{domain_payload}}"
					
						if (parent_flag == true)
							if (assign_domain_to_subuser == "false")
								puts "Creating Domain Authentication for '#{domain_subdomain}.#{domain}' on user '#{username}'"
								response = HTTParty.post("https://api.sendgrid.com/v3/whitelabel/domains", body: domain_payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
								#puts domain_payload
								#puts username
								response_json = JSON.parse(response.to_s)
								###CAPTURE DNS RECORDS###
								if (response.code == 201)
									puts "Success"
									if (automatic_security == "true")
										domain_type1 = response_json["dns"]["mail_cname"]["type"]
										domain_host1 =response_json["dns"]["mail_cname"]["host"]
										domain_data1 =response_json["dns"]["mail_cname"]["data"]

										domain_type2 = response_json["dns"]["dkim1"]["type"]
										domain_host2 =response_json["dns"]["dkim1"]["host"]
										domain_data2 =response_json["dns"]["dkim1"]["data"]

										domain_type3 = response_json["dns"]["dkim2"]["type"]
										domain_host3 =response_json["dns"]["dkim2"]["host"]
										domain_data3 =response_json["dns"]["dkim2"]["data"]
									else
										domain_type1 = response_json["dns"]["mail_server"]["type"]
										domain_host1 =response_json["dns"]["mail_server"]["host"]
										domain_data1 =response_json["dns"]["mail_server"]["data"]

										domain_type2 = response_json["dns"]["subdomain_spf"]["type"]
										domain_host2 =response_json["dns"]["subdomain_spf"]["host"]
										domain_data2 =response_json["dns"]["subdomain_spf"]["data"]

										domain_type3 = response_json["dns"]["dkim"]["type"]
										domain_host3 =response_json["dns"]["dkim"]["host"]
										domain_data3 =response_json["dns"]["dkim"]["data"]
									end
								else
									puts "ERROR: \n #{response.code} - #{response}"
								end
								#puts domain_payload
							else
								puts "Creating Domain Authentication for '#{domain_subdomain}.#{domain}' on user '#{username}' and assigning to '#{assign_domain_to_subuser}'"
								response = HTTParty.post("https://api.sendgrid.com/v3/whitelabel/domains", body: domain_payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
				
								response_json = JSON.parse(response.to_s)
								###CAPTURE DNS RECORDS###
								if (response.code == 201)
									puts "Success"
									if (automatic_security == "true")
										domain_type1 = response_json["dns"]["mail_cname"]["type"]
										domain_host1 =response_json["dns"]["mail_cname"]["host"]
										domain_data1 =response_json["dns"]["mail_cname"]["data"]

										domain_type2 = response_json["dns"]["dkim1"]["type"]
										domain_host2 =response_json["dns"]["dkim1"]["host"]
										domain_data2 =response_json["dns"]["dkim1"]["data"]

										domain_type3 = response_json["dns"]["dkim2"]["type"]
										domain_host3 =response_json["dns"]["dkim2"]["host"]
										domain_data3 =response_json["dns"]["dkim2"]["data"]

										domain_id = response_json["id"]
									else
										domain_type1 = response_json["dns"]["mail_server"]["type"]
										domain_host1 =response_json["dns"]["mail_server"]["host"]
										domain_data1 =response_json["dns"]["mail_server"]["data"]

										domain_type2 = response_json["dns"]["subdomain_spf"]["type"]
										domain_host2 =response_json["dns"]["subdomain_spf"]["host"]
										domain_data2 =response_json["dns"]["subdomain_spf"]["data"]

										domain_type3 = response_json["dns"]["dkim"]["type"]
										domain_host3 =response_json["dns"]["dkim"]["host"]
										domain_data3 =response_json["dns"]["dkim"]["data"]

										domain_id = response_json["id"]
									end
									puts "Assigning Domain Authentication for '#{domain_subdomain}.#{domain}' to subuser '#{assign_domain_to_subuser}'"
									response = HTTParty.post("https://api.sendgrid.com/v3/whitelabel/domains/#{domain_id}/subuser", body: "{\"username\": \"#{assign_domain_to_subuser}\"}", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
									response_json = JSON.parse(response.to_s)
									## CONFIRM ASSIGNED##
									if (response.code == 201)						
										puts "Assigned Domain Authentication for '#{domain_subdomain}.#{domain}' to subuser '#{assign_domain_to_subuser}'"
									else
										puts "ERROR: \n #{response.code} - #{response}"
									end
								else
									puts "ERROR: \n #{response.code} - #{response}"
								end
								#puts domain_payload
							end
						end
						if (parent_flag == false)
							puts "Creating Domain Authentication for '#{domain_subdomain}.#{domain}' on user '#{username}'"
							response = HTTParty.post("https://api.sendgrid.com/v3/whitelabel/domains", body: domain_payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json", "on-behalf-of" => "#{username}"})
							#puts domain_payload
							#puts username
							response_json = JSON.parse(response.to_s)
							###CAPTURE DNS RECORDS###
							if (response.code == 201)
								puts "Success"
									if (automatic_security == "true")
										domain_type1 = response_json["dns"]["mail_cname"]["type"]
										domain_host1 =response_json["dns"]["mail_cname"]["host"]
										domain_data1 =response_json["dns"]["mail_cname"]["data"]

										domain_type2 = response_json["dns"]["dkim1"]["type"]
										domain_host2 =response_json["dns"]["dkim1"]["host"]
										domain_data2 =response_json["dns"]["dkim1"]["data"]

										domain_type3 = response_json["dns"]["dkim2"]["type"]
										domain_host3 =response_json["dns"]["dkim2"]["host"]
										domain_data3 =response_json["dns"]["dkim2"]["data"]
									else
										domain_type1 = response_json["dns"]["mail_server"]["type"]
										domain_host1 =response_json["dns"]["mail_server"]["host"]
										domain_data1 =response_json["dns"]["mail_server"]["data"]

										domain_type2 = response_json["dns"]["subdomain_spf"]["type"]
										domain_host2 =response_json["dns"]["subdomain_spf"]["host"]
										domain_data2 =response_json["dns"]["subdomain_spf"]["data"]

										domain_type3 = response_json["dns"]["dkim"]["type"]
										domain_host3 =response_json["dns"]["dkim"]["host"]
										domain_data3 =response_json["dns"]["dkim"]["data"]
									end
								else
									puts "ERROR: \n #{response.code} - #{response}"
								end
							#puts domain_payload
						end
				end
			else
				puts "Invalid input for 'default_domain' on #{mail_stream_name}'"
				exit
			end
		else
			puts "Invalid input for 'automatic_security' on #{mail_stream_name}'"
			exit
		end
	else
		puts "Invalid input for 'create_domain' on #{mail_stream_name}'"
		exit
	end

	if (create_link == "true" || create_link == "false")
		if (default_link == "true" || default_link == "false")
			if (create_link == "true")
				link_payload = "#{link_payload}, \"default\": #{default_link}}"
				puts "Creating Link Branding for '#{link_subdomain}.#{domain}'"
				response = HTTParty.post("https://api.sendgrid.com/v3/whitelabel/links", body: link_payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})

				response_json = JSON.parse(response.to_s)
				###CAPTURE DNS RECORDS###
				if (response.code == 201)
					puts "Success"						
					link_type1 = response_json["dns"]["domain_cname"]["type"]
					link_host1 =response_json["dns"]["domain_cname"]["host"]
					link_data1 =response_json["dns"]["domain_cname"]["data"]

					link_type2 = response_json["dns"]["owner_cname"]["type"]
					link_host2 =response_json["dns"]["owner_cname"]["host"]
					link_data2 =response_json["dns"]["owner_cname"]["data"]

					link_id = response_json["id"]
				else
					puts "ERROR: \n #{response.code} - #{response}"
				end
				#puts link_payload
				if !(assign_link_to_subuser == "false")
					assign_to_sub_flag = true
				end
				if !(assign_to_sub_flag == false)
					puts "Assigning Link Branding for '#{link_subdomain}.#{domain}' to subuser '#{assign_link_to_subuser}'"
					response = HTTParty.post("https://api.sendgrid.com/v3/whitelabel/links/#{link_id}/subuser", body: "{\"username\": \"#{assign_link_to_subuser}\"}", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
					response_json = JSON.parse(response.to_s)
					## CONFIRM ASSIGNED##
					if (response.code == 201)						
						puts "Assigned Link Brand for '#{link_subdomain}.#{domain}' to subuser '#{assign_link_to_subuser}'"
					else
						puts "ERROR: \n #{response.code} - #{response}"
					end
					#puts "{\"username\": \"#{assign_link_to_subuser}\"}"
				end
			end
		else
			puts "Invalid input for 'default_link' on #{mail_stream_name}'"
			exit
		end
	else
		puts "Invalid input for 'create_link' on #{mail_stream_name}'"
		exit
	end

	if (create_rdns == "true" || create_rdns == "false")
		if (create_rdns == "true")
			puts "Creating rDNS for '#{rdns_subdomain}.#{domain}' on '#{ip}'"
			rdns_payload = "{\"ip\": \"#{ip}\", \"subdomain\": \"#{rdns_subdomain}\", \"domain\": \"#{domain}\"}"
			response = HTTParty.post("https://api.sendgrid.com/v3/whitelabel/ips", body: rdns_payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
			response_json = JSON.parse(response.to_s)
			###CAPTURE DNS RECORDS###
			if (response.code == 201)
				puts "Success"						
				rdns_type1 = response_json["a_record"]["type"]
				rdns_host1 =response_json["a_record"]["host"]
				rdns_data1 =response_json["a_record"]["data"]
			
			else
				puts "ERROR: \n #{response.code} - #{response}"
			end
			#puts rdns_payload
		end	
	else
		puts "Invalid input for 'create_rdns' on #{mail_stream_name}'"
		exit
	end

	if (i == 0)
		CSV.open("#{parent_username}-DNS.csv", "w")
	end
	#mail stream
	CSV.open("#{parent_username}-DNS.csv", "ab") do |csv| 
		csv << ["#{mail_stream_name}"] 
		csv << ["Type", "Host", "Value"]
	end
  	if (create_domain == "true")
		#domain
	  	CSV.open("#{parent_username}-DNS.csv", "ab") do |csv| 
	  		csv << ["#{domain_type1}", "#{domain_host1}", "#{domain_data1}"]
		  	csv << ["#{domain_type2}", "#{domain_host2}", "#{domain_data2}"]
		  	csv << ["#{domain_type3}", "#{domain_host3}", "#{domain_data3}"] 
	  	end
  	end
  	if (create_link == "true")
	  	#link
	  	CSV.open("#{parent_username}-DNS.csv", "ab") do |csv|
		  	csv << ["#{link_type1}", "#{link_host1}", "#{link_data1}"]
		  	csv << ["#{link_type2}", "#{link_host2}", "#{link_data2}"]
		end
	end
  	if (create_rdns == "true")
	  	#rdns
	  	CSV.open("#{parent_username}-DNS.csv", "ab") do |csv|
	  		csv << ["#{rdns_type1}", "#{rdns_host1}", "#{rdns_data1}"]
	  	end
	end
  	#insert row
  	CSV.open("#{parent_username}-DNS.csv", "ab") do |csv|
  		csv << [""]
  	end
	i = i + 1
	domain_type1 = ""
	domain_type2 = ""
	domain_type3 = ""
	domain_host1 = ""
	domain_host2 = ""
	domain_host3 = ""
	domain_data1 = ""
	domain_data2 = ""
	domain_data3 = ""
	link_type1 = ""
	link_type2 = ""
	link_host1 = ""
	link_host2 = ""
	link_data1 = ""
	link_data2 = ""
	rdns_type1 = ""
	rdns_host1 = ""
	rdns_data1 = ""
end

puts "Success.. CSV Written to - #{parent_username}-DNS.csv"
