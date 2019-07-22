# ruby bulk_email_validation.rb filename.csv
# 
# file MUST be a proper CSV format, with a single first column, with "email" as only header row.

require 'httparty'
require 'json'
require 'csv'
# csv_write() Adpated from https://github.com/sendgrid/support_scripts/blob/master/webapi_scripts/v3_unsub-delete.rb 
@csv_perm = "a"
def csv_write(csv_file, result_array, headers)
    CSV.open(csv_file, @csv_perm, {:force_quotes=>true}) { |csv| result_array.each { |result| csv << [result]}}
end

input = ARGV[0]
email_array = []
email  = []
verdict  = []
score  = []
local  = []
host  = []
suggestion  = []
checks  = []
# move input CSV to array
CSV.foreach(input, headers: true) do |row| 
	email_array.push(row[0])
end
size = email_array.length
puts "Total email addresses: #{size}"
##
token = "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"
i = 0
mod = size / 100
mod = mod.ceil
percent = 0
while (i < size) do
	payload = "{\"email\": \"#{email_array[i]}\"}"
	response1 = HTTParty.post("https://api.sendgrid.com/v3/validations/email", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
	if response1.headers['x-ratelimit-remaining'] == "0"
	    puts "hitting rate limit, sleeping for a few seconds"
	    sleep(1) until Time.now.to_i >= response1.headers['x-ratelimit-reset'].to_i
	    response1 = HTTParty.post("https://api.sendgrid.com/v3/validations/email", body: payload, headers: {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"})
	end
	if (response1.code.to_s != "200")
		puts "Error validating '#{email_array[i]}' | ERROR: #{response1.code} - #{response1}"
		#break if (response1.code.to_s != "201")
	else
		email[i] = response1["result"]["email"]
		verdict[i] = response1["result"]["verdict"]
		score[i] = response1["result"]["score"]
		local[i] = response1["result"]["local"]
		host[i] = response1["result"]["host"]
		suggestion[i] = response1["result"]["suggestion"]
		checks[i] = response1["result"]["checks"].to_s
	end
	#puts "#{i}"
	if (i % mod == 0)
		puts "#{percent}\% complete"
		percent = percent + 1
	end
	i = i + 1
end
puts "Writing results to a CSV..."
CSV.open("test_results.csv", "w")
		CSV.open("test_results.csv", "ab") do |csv| 
		csv << ["email", "verdict", "score", "local", "host", "suggestion" ,"checks"]
		end
table = [email, verdict, score, local, host, suggestion, checks].transpose
CSV.open("test_results.csv", "ab") do |csv|
    table.each do |row|
        csv << row
    end
end
#csv_write("test_results.csv", email_array.flatten, "email")
puts "Valid emails written to 'test_results.csv'"
