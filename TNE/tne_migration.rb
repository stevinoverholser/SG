# tne_migration.rb
# All TNE contact list names can not be the same as legacy names
# All TNE Custom Field names can not be the same as legacy names
# Legacy list can not have a no exactly "Recipients on no list" 
require 'httparty'
require 'json'
require 'time'


# Get users API key
puts "Please enter API key: "
token = gets.chomp
# Migrate Custom Fields
page = 1
page_size = 1000

# Handle contacts not on a list

all = []
list = []

# Get all contacts on legacy ALL CONTACTS

more_pages = true
puts "Creating list of all contacts not on a list. This may take a few minutes"
while (more_pages) do
	response_all = HTTParty.get("https://api.sendgrid.com/v3/contactdb/recipients?page=#{page}&page_size=#{page_size}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
	#puts response_all.code.to_s
	if response_all.headers["x-ratelimit-remaining"] == "0"
		puts "hitting rate limit, sleeping for a few seconds"
		sleep(1) until Time.now.to_i >= response_all.headers['x-ratelimit-reset'].to_i
		response_all = HTTParty.get("https://api.sendgrid.com/v3/contactdb/recipients?page=#{page}&page_size=#{page_size}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
	end
	if (response_all.code.to_s != "200" && response_all.code.to_s != "404")
		puts "Error retreiving recipients on list '#{response["lists"][i]["name"]}' | ERROR: #{response_all.code} - #{response_all}"
		#break if (response2.code.to_s != "200" && response2.code.to_s != "404")
	end
	if (response_all.code.to_s == "404")
		more_pages = false
	end
	if (response_all.code.to_s == "200")
		#puts response_all["recipients"].count
		j = 0
		while (j < response_all["recipients"].count) do
			all.push(response_all["recipients"][j]["id"])
			#puts "#{j} - #{all[j]}"
			j = j + 1
		end
	end
	puts "...#{page}..."
	page = page + 1
end

puts "All contacts number = #{all.count}"

##############
puts "Migrating Custom Fields"

custom_fields = HTTParty.get("https://api.sendgrid.com/v3/contactdb/custom_fields", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
tne_custom_fields = [[]]
h = 0
while (h < custom_fields["custom_fields"].count) do 
	
		custom_fields["custom_fields"][h].delete("id")
		puts "Migrating Custom Field '#{custom_fields["custom_fields"][h]["name"]}'"
		payload = "{\"name\": \"#{custom_fields["custom_fields"][h]["name"]}\", \"field_type\": \"#{custom_fields["custom_fields"][h]["type"].capitalize}\"}"
		##puts payload
		response0 = HTTParty.post("https://api.sendgrid.com/v3/marketing/field_definitions", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
		if response0.headers['x-ratelimit-remaining'] == "0"
		    puts "hitting rate limit, sleeping for a few seconds"
		    sleep(1) until Time.now.to_i >= response0.headers['x-ratelimit-reset'].to_i
		    response0 = HTTParty.post("https://api.sendgrid.com/v3/marketing/field_definitions", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
		end
		#puts response0
		if (response0.code.to_s == "200")
			tne_custom_fields.push([response0["id"],response0["name"],response0["field_type"]])
		end
		#puts tne_custom_fields
		h = h + 1
end

# Get all old list names to recreate
response = HTTParty.get("https://api.sendgrid.com/v3/contactdb/lists", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
if response.headers['x-ratelimit-remaining'] == "0"
    puts "hitting rate limit, sleeping for a few seconds"
    sleep(1) until Time.now.to_i >= response.headers['x-ratelimit-reset'].to_i
    response = HTTParty.get("https://api.sendgrid.com/v3/contactdb/lists", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
end
if (response.code.to_s != "200")
	puts "Error retreiving lists | ERROR: #{response.code} - #{response}"
end

# Itterate through all lists
CSV.open("-ERROR.csv", "w")
CSV.open("-ERROR.csv", "ab") do |csv| 
	csv << ["Error Code", "Error Reason", "Payload"]
end
i = 0
##############

while (i < response["lists"].count) do 

	puts "Migrating List '#{response["lists"][i]["name"]}' - ID: #{response["lists"][i]["id"]} - Recipient Count: #{response["lists"][i]["recipient_count"]}"

	no_put_flag = response["lists"][i]["recipient_count"]
	#puts no_put_flag
	# Recreate list in TNE
	payload = "{\"name\": \"#{response["lists"][i]["name"]}\"}"
	response1 = HTTParty.post("https://api.sendgrid.com/v3/marketing/lists", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})

	if response1.headers['x-ratelimit-remaining'] == "0"
	    puts "hitting rate limit, sleeping for a few seconds"
	    sleep(1) until Time.now.to_i >= response1.headers['x-ratelimit-reset'].to_i
	    response1 = HTTParty.post("https://api.sendgrid.com/v3/marketing/lists", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
	end
	if (response1.code.to_s != "201")
		puts "Error creating list '#{response["lists"][i]["name"]}' in TNE | ERROR: #{response1.code} - #{response1}"
		#break if (response1.code.to_s != "201")
	end
	listID = response1["id"]
	#puts "new listid = #{listID}"
	#puts " meta data? = #{response1["_metadata"]["self"]}"

	
	####################
	# Get contacts on this list
	page = 1
	more_pages = true
	r_count = 0
	while (more_pages) do
		#puts "after while"
		response2 = HTTParty.get("https://api.sendgrid.com/v3/contactdb/lists/#{response["lists"][i]["id"]}/recipients?page=#{page}&page_size=#{page_size}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
		#puts "#{response2.code.to_s} = https://api.sendgrid.com/v3/contactdb/lists/#{response["lists"][i]["id"]}/recipients?page=#{page}&page_size=#{page_size}"
		if response2.headers["x-ratelimit-remaining"] == "0"
		    puts "hitting rate limit, sleeping for a few seconds"
		    sleep(1) until Time.now.to_i >= response2.headers['x-ratelimit-reset'].to_i
		    response2 = HTTParty.get("https://api.sendgrid.com/v3/contactdb/lists/#{response["lists"][i]["id"]}/recipients?page=#{page}&page_size=#{page_size}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
		end
		if (response2.code.to_s != "200" && response2.code.to_s != "404")
			puts "Error retreiving recipients on list '#{response["lists"][i]["name"]}' | ERROR: #{response2.code} - #{response2}"
			#break if (response2.code.to_s != "200" && response2.code.to_s != "404")
		end
		if (response2.code.to_s == "404")
			more_pages = false
		end
		if (response2.code.to_s == "200")
			# Add contacts 
			#puts "after if"
			j = 0
			#puts response2["recipients"].count
			r_count = r_count + response2["recipients"].count
			while (j < response2["recipients"].count) do
				list.push(response2["recipients"][j]["id"])
				response2["recipients"][j].delete("created_at")
				response2["recipients"][j].delete("updated_at")
				response2["recipients"][j].delete("last_emailed")
				response2["recipients"][j].delete("last_clicked")
				response2["recipients"][j].delete("last_opened")
				response2["recipients"][j].delete("id")
				#CF HANDELING
				x = 0
				old_c_f = response2["recipients"][j]["custom_fields"]
				#puts old_c_f
				new_c_f = [[]]
				while (x < old_c_f.length) do
					y = 0
					while (y < tne_custom_fields.length) do
						if (old_c_f[x]["name"].to_s == tne_custom_fields[y][1].to_s)
							if (old_c_f[x]["value"].nil?)
								#puts "HERE"
								old_c_f[x]["value"] = ""
							end
							if (tne_custom_fields[y][2] == "Date" && old_c_f[x]["value"] != "")
								old_c_f[x]["value"] = Time.at(old_c_f[x]["value"]).iso8601
								#puts old_c_f[x]["value"]
								new_c_f[x] = [tne_custom_fields[y][0],old_c_f[x]["value"]]
								#puts new_c_f[x].to_s
							else
								new_c_f[x] = [tne_custom_fields[y][0],old_c_f[x]["value"]]
							end
						end 
						y = y + 1
					end
					#puts old_c_f[x]["name"].to_s
					if (old_c_f[x]["name"].to_s == "alternate_emails" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"alternate_emails" => ["#{old_c_f[x]["value"]}"]})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "address_line_1" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"address_line_1" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "address_line_2" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"address_line_2" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "city" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"city" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "state_province_region" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"state_province_region" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "postal_code" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"postal_code" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "country" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"country" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "phone_number" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"phone_number" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "whatsapp" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"whatsapp" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "facebook" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"facebook" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "line" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"line" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "unique_name" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"unique_name" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					
					x = x + 1
				end
				new_c_f.delete(nil)
				new_c_f_string = new_c_f.to_s
				#puts new_c_f_string
				new_c_f_string[0] = "\"custom_fields\" : {"
				new_c_f_string[new_c_f_string.length-1] = "}"
				new_c_f_string.gsub! "\",","\":"
				new_c_f_string.gsub! "]", ""
				#puts new_c_f_string
				new_c_f_string.gsub! "[",""
				#############
				response2["recipients"][j].delete("custom_fields")
				#puts response2["recipients"]
				recip_list = response2["recipients"][j].to_json
				#puts recip_list
				recip_list.gsub! "}", ""
				#puts recip_list
				#recip_list = "#{response2["recipients"].to_s}, \"custom_fields\": #{new_c_f_string}"
				#recip_list = response2["recipients"].to_json
				contacts = "#{recip_list} , #{new_c_f_string}"
				
				if (j == 0)
					contacts_final = contacts 
				else
					contacts_final = "#{contacts_final} }, #{contacts}"
				end
				payload = "{ \"list_ids\": [\"#{response1["id"]}\"], \"contacts\": [#{contacts_final}}]}"
				#payload = "{ \"list_ids\": [\"#{response1["id"]}\"], \"contacts\": [#{recip_list} #{new_c_f_string}}]}"
				#puts payload
				j = j + 1
			end
			#################### add batched put calls
			if (no_put_flag > 0)
				puts "Making PUT call adding recipient, #{r_count} out of #{response2["recipient_count"]} recipients"
				#puts "****************PAYLOAD******************"
				#puts payload
				response3 = HTTParty.put("https://api.sendgrid.com/v3/marketing/contacts", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
				#puts response3
				#puts response3.code.to_s
				puts "Completed PUT call"
				if response3.headers['x-ratelimit-remaining'] == "0"
				    puts "hitting rate limit, sleeping for a few seconds"
				    sleep(1) until Time.now.to_i >= response3.headers['x-ratelimit-reset'].to_i
				    response3 = HTTParty.put("https://api.sendgrid.com/v3/marketing/contacts", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
				end
				if (response3.code.to_s != "202")
					#puts "Error uploading recipients on list #{response["lists"][i]["name"]}' recipient: '#{response3["recipients"][j]["email"]}' | ERROR: #{response3.code} - #{response3}"
					puts "Error uploading recipients on list #{response["lists"][i]["name"]}' | ERROR: #{response3.code} - #{response3}"
					puts "Writing to CSV - \"-ERROR.csv\""
					#break if (response2.code.to_s != "200" && response2.code.to_s != "404")
					CSV.open("-ERROR.csv", "ab") do |csv| 
	  				csv << ["#{response3.code}", "#{response3}", "#{payload}"]
	  				end
				end
			end
			page = page + 1
		end
		
	end
		#puts response3
		#puts "{ \"list_ids\": [\"list ids\"], \"contacts\": #{recip_list} #{new_c_f_string}}]}"
	i = i + 1
end

to_up = all.reject{|x| list.include? x}
#puts "NOT ON LIST = #{to_up.count}"
#puts to_up
#puts to_up.count
if (to_up.count == 0)
	all_on_list = true
end
# Create a list on legacy of to_up array to preserve custom fields
list_response = HTTParty.post("https://api.sendgrid.com/v3/contactdb/lists", body: "{\"name\": \"Recipients on no list\"}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
if list_response.headers["x-ratelimit-remaining"] == "0"
	puts "hitting rate limit, sleeping for a few seconds"
	sleep(1) until Time.now.to_i >= list_response.headers['x-ratelimit-reset'].to_i
	list_response = HTTParty.post("https://api.sendgrid.com/v3/contactdb/lists", body: "{\"name\": \"Recipients on no list\"}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
end
if (list_response.code.to_s != "201")
	puts "Error retreiving lists associated with recipient '#{list_response["name"]}' | ERROR: #{list_response.code} - #{list_response}"
end
if (!all_on_list)
	disp_count = to_up.count
	count = to_up.count / 1000
	k = 0
	while (k <= count.ceil) do
		payload = to_up.pop(1000).to_s
		##puts payload
		#puts "https://api.sendgrid.com/v3/contactdb/lists/#{list_response["id"]}/recipients"
		response4 = HTTParty.post("https://api.sendgrid.com/v3/contactdb/lists/#{list_response["id"]}/recipients", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
		if response4.headers['x-ratelimit-remaining'] == "0"
			puts "hitting rate limit, sleeping for a few seconds"
			sleep(1) until Time.now.to_i >= response4.headers['x-ratelimit-reset'].to_i
			response4 = HTTParty.post("https://api.sendgrid.com/v3/contactdb/lists/#{list_response["id"]}/recipients", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
		end
		if (response4.code.to_s != "201")
			puts "Error uploading recipients on list 'Recipients on no list' | ERROR: #{response4.code} - #{response4}"
			##puts payload
			#break if (response2.code.to_s != "200" && response2.code.to_s != "404")
		end
		k = k + 1
	end
	# Upload this list to TNE

	####
	page = 1
	more_pages = true
	r_count = 0
	puts "Migrating contacts not on any lists - Recipient Count: #{disp_count}"
	#payload = "{\"name\": \"#{list_response["name"]}\"}"
	#response7 = HTTParty.post("https://api.sendgrid.com/v3/marketing/lists", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
	#if response7.headers['x-ratelimit-remaining'] == "0"
	#    puts "hitting rate limit, sleeping for a few seconds"
	#    sleep(1) until Time.now.to_i >= response7.headers['x-ratelimit-reset'].to_i
	#    response7 = HTTParty.post("https://api.sendgrid.com/v3/marketing/lists", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
	#end
	#if (response7.code.to_s != "201")
	#	puts "Error creating list '#{list_response["name"]}' in TNE | ERROR: #{response7.code} - #{response7}"
	#	#break if (respons7.code.to_s != "201")
	#end
	#listID = response7["id"]
	while (more_pages) do
		#puts "after while"
		response5 = HTTParty.get("https://api.sendgrid.com/v3/contactdb/lists/#{list_response["id"]}/recipients?page=#{page}&page_size=#{page_size}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
		#puts "#{response5.code.to_s} = https://api.sendgrid.com/v3/contactdb/lists/#{response["lists"][i]["id"]}/recipients?page=#{page}&page_size=#{page_size}"
		if response5.headers["x-ratelimit-remaining"] == "0"
			puts "hitting rate limit, sleeping for a few seconds"
			sleep(1) until Time.now.to_i >= response5.headers['x-ratelimit-reset'].to_i
			response5 = HTTParty.get("https://api.sendgrid.com/v3/contactdb/lists/#{list_response["id"]}/recipients?page=#{page}&page_size=#{page_size}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
		end
		if (response5.code.to_s != "200" && response5.code.to_s != "404")
			puts "Error retreiving recipients on list '#{list_response["name"]}' | ERROR: #{response5.code} - #{response5}"
			#break if (response5.code.to_s != "200" && response5.code.to_s != "404")
		end
		if (response5.code.to_s == "404")
			more_pages = false
		end

		if (response5.code.to_s == "200")
			# Add contacts 
			#puts "after if"
			while (response5["recipient_count"] != disp_count) do
				puts "Sleeping for 15 seconds for DB lag | #{response5["recipient_count"]} != #{disp_count}"
				sleep(15)
				response5 = HTTParty.get("https://api.sendgrid.com/v3/contactdb/lists/#{list_response["id"]}/recipients?page=#{page}&page_size=#{page_size}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
				#puts "#{response5.code.to_s} = https://api.sendgrid.com/v3/contactdb/lists/#{response["lists"][i]["id"]}/recipients?page=#{page}&page_size=#{page_size}"
				if response5.headers["x-ratelimit-remaining"] == "0"
					puts "hitting rate limit, sleeping for a few seconds"
					sleep(1) until Time.now.to_i >= response5.headers['x-ratelimit-reset'].to_i
					response5 = HTTParty.get("https://api.sendgrid.com/v3/contactdb/lists/#{list_response["id"]}/recipients?page=#{page}&page_size=#{page_size}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
				end
			end
=begin
			while ((1000 - response5["recipients"].count) > 200) do
				response5 = HTTParty.get("https://api.sendgrid.com/v3/contactdb/lists/#{list_response["id"]}/recipients?page=#{page}&page_size=#{page_size}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
				if response5.headers["x-ratelimit-remaining"] == "0"
					puts "hitting rate limit, sleeping for a few seconds"
					sleep(1) until Time.now.to_i >= response5.headers['x-ratelimit-reset'].to_i
					response5 = HTTParty.get("https://api.sendgrid.com/v3/contactdb/lists/#{list_response["id"]}/recipients?page=#{page}&page_size=#{page_size}", headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
				end
				if (response5.code.to_s != "200" && response5.code.to_s != "404")
					puts "Error retreiving recipients on list '#{list_response["name"]}' | ERROR: #{response5.code} - #{response5}"
					#break if (response5.code.to_s != "200" && response5.code.to_s != "404")
				end
				puts "Sleeping for 15 seconds for DB lag | page size too small at #{response5["recipients"].count}"
				sleep(15)
			end
=end
			j = 0
			r_count = r_count + response5["recipients"].count
			#puts response5["recipients"].count
			while (j < response5["recipients"].count) do
				response5["recipients"][j].delete("created_at")
				response5["recipients"][j].delete("updated_at")
				response5["recipients"][j].delete("last_emailed")
				response5["recipients"][j].delete("last_clicked")
				response5["recipients"][j].delete("last_opened")
				response5["recipients"][j].delete("id")
				#CF HANDELING
				x = 0
				old_c_f = response5["recipients"][j]["custom_fields"]
				#puts old_c_f
				new_c_f = [[]]
				while (x < old_c_f.length) do
					y = 0
					while (y < tne_custom_fields.length) do
						if (old_c_f[x]["name"].to_s == tne_custom_fields[y][1].to_s)
							if (old_c_f[x]["value"].nil?)
								#puts "HERE"
								old_c_f[x]["value"] = ""
							end
							if (tne_custom_fields[y][2] == "Date" && old_c_f[x]["value"] != "")
								old_c_f[x]["value"] = Time.at(old_c_f[x]["value"]).iso8601
								#puts old_c_f[x]["value"].to_s
								new_c_f[x] = [tne_custom_fields[y][0],old_c_f[x]["value"]]
							else
								new_c_f[x] = [tne_custom_fields[y][0],old_c_f[x]["value"]]
							end
						end 
							y = y + 1
					end

					if (old_c_f[x]["name"].to_s == "alternate_emails" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"alternate_emails" => ["#{old_c_f[x]["value"]}"]})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "address_line_1" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"address_line_1" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "address_line_2" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"address_line_2" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "city" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"city" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "state_province_region" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"state_province_region" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "postal_code" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"postal_code" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "country" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"country" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "phone_number" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"phone_number" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "whatsapp" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"whatsapp" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "facebook" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"facebook" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "line" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"line" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end
					if (old_c_f[x]["name"].to_s == "unique_name" && old_c_f[x]["value"] != nil)
							response2["recipients"][j].merge!({"unique_name" => "#{old_c_f[x]["value"]}"})
							#puts response2["recipients"][j]
					end

					x = x + 1
				end


				### ADD PREV CF HANDELING ###

				new_c_f.delete(nil)
				new_c_f_string = new_c_f.to_s
				#puts new_c_f_string
				new_c_f_string[0] = "\"custom_fields\" : {"
				new_c_f_string[new_c_f_string.length-1] = "}"
				new_c_f_string.gsub! "\",","\":"
				new_c_f_string.gsub! "]", ""
				#puts new_c_f_string
				new_c_f_string.gsub! "[",""
				#############
				response5["recipients"][j].delete("custom_fields")
				#puts response5["recipients"]
				recip_list = response5["recipients"][j].to_json
				#puts recip_list
				recip_list.gsub! "}", ""
				#puts recip_list
				#recip_list = "#{response5["recipients"].to_s}, \"custom_fields\": #{new_c_f_string}"
				#recip_list = response5["recipients"].to_json
				contacts = "#{recip_list} , #{new_c_f_string}"
				
				if (j == 0)
					contacts_final = contacts 
				else
					contacts_final = "#{contacts_final} }, #{contacts}"
				end
				payload = "{\"contacts\": [#{contacts_final}}]}"
				#payload = "{ \"list_ids\": [\"#{response1["id"]}\"], \"contacts\": [#{recip_list} #{new_c_f_string}}]}"
				##puts payload
				j = j + 1
			end
			#################### add batched put calls
			puts "Making PUT call adding recipient #{r_count} out of #{response5["recipient_count"]} recipients"
			response6 = HTTParty.put("https://api.sendgrid.com/v3/marketing/contacts", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
			puts "Completed PUT call"
			#puts payload
			if response6.headers['x-ratelimit-remaining'] == "0"
			    puts "hitting rate limit, sleeping for a few seconds"
			    sleep(1) until Time.now.to_i >= response6.headers['x-ratelimit-reset'].to_i
			    response6 = HTTParty.put("https://api.sendgrid.com/v3/marketing/contacts", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
			end
			if (response6.code.to_s != "202")
				puts "Error uploading recipients on list '#{list_response["name"]}' | ERROR: #{response6.code} - #{response6}"
				#break if (response5.code.to_s != "200" && response5.code.to_s != "404")
				puts "Writing to CSV - \"-ERROR.csv\""
					#break if (response2.code.to_s != "200" && response2.code.to_s != "404")
					CSV.open("-ERROR.csv", "ab") do |csv| 
	  				csv << ["#{response6.code}", "#{response6}", "#{payload}"]
	  				end
			end
			#puts page
			#puts "#{response5.code} - #{response5["recipients"].count} - https://api.sendgrid.com/v3/contactdb/lists/#{list_response["id"]}/recipients?page=#{page}&page_size=#{page_size}"
			#puts response5
			page = page + 1
		end

	end
end
####
puts "Script complete"
