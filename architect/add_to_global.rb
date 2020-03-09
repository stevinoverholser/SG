#add_to_global.rb
# ruby add_to_global.rb input.csv {MAKO_AUTH_TOKEN}

require 'httparty'
require 'json'
require 'csv'
# 

input = ARGV[0]
email_array = []
CSV.foreach(input, headers: true) do |row| 
	email_array.push(row[0])
end
size = email_array.length
puts "Total email addresses: #{size}"
token = ARGV[1].to_s

#cleaning data
#duplicates
#nil values
#Double quote is replaced with \"
#Backslash is replaced with \\

sizea = email_array.length
puts "Removing nil values"
email_array.delete(nil)
sizeb = email_array.length
size = sizea - sizeb
puts "#{size} nil values removed"
sizea = email_array.length
#lowercase all emails
j=0
while (j<sizea-1) do
	#puts "#{email_array[j]}"
	email_array[j] = email_array[j].downcase
	email_array[j].gsub!("\"", ",\\\"")
	email_array[j].gsub!("\\", "\\\\")
	#puts "#{email_array[j]}"
	j=j+1
end
puts "Removing duplicates"
email_array = email_array.uniq
sizeb = email_array.length
size = sizea - sizeb 
puts "#{size} duplicate emails removed"
size = email_array.length
post_array = email_array.each_slice(25000).to_a
size = post_array.length
error_count = 0
# do batches of 25K 
#some while loop
i = 0
while (i < size) do
	payload = "{\"recipient_emails\": [\"" + post_array[i].join("\",\"") + "\"]}"
	#puts payload
	puts "Adding #{post_array[i].size} to Global Unsub list"
	response1 = HTTParty.post("https://api.sendgrid.com/v3/asm/suppressions/global", body: payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	if response1.headers['x-ratelimit-remaining'] == "0"
	    puts "hitting rate limit, sleeping for a few seconds"
	    sleep(1) until Time.now.to_i >= response1.headers['x-ratelimit-reset'].to_i
	    response1 = HTTParty.post("https://api.sendgrid.com/v3/asm/suppressions/global", body: payload, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	end
	if (response1.code == 201)
		puts "Success"						
	else
		puts "ERROR: \n #{response1.code} - #{response1}"
		error_count = error_count + 1
	end
	i = i + 1
end

# end while loop
