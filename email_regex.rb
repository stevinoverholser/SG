# valid email regex
#\b[a-zA-Z0-9!#$%&'*+-\/=?^_`.{|}~]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b
# ruby email_regex.rb filename.csv
# 
# file MUST be a proper CSV format, with a single first column, with "email" as only header row.


require 'csv'
# csv_write() Adpated from https://github.com/sendgrid/support_scripts/blob/master/webapi_scripts/v3_unsub-delete.rb 
@csv_perm = "a"
def csv_write(csv_file, result_array, headers)
    CSV.open(csv_file, @csv_perm, {:force_quotes=>true}) { |csv| result_array.each { |result| csv << [result]}}
end

input = ARGV[0]
email_array = []

# move input CSV to array
CSV.foreach(input, headers: true) do |row| 
	email_array.push(row[0])
end
size = email_array.length
puts "Total email addresses: #{size}"
#puts email_array.inspect
# remove any empty cells
sizea = email_array.length
puts "Removing nil values"
email_array.delete(nil)
sizeb = email_array.length
size = sizea - sizeb
puts "#{size} nil values removed"
# remove duplicate email
sizea = email_array.length
#lowercase all emails
j=0
while (j<sizea-1) do
	#puts "#{email_array[j]}"
	email_array[j] = email_array[j].downcase
	#puts "#{email_array[j]}"
	j=j+1
end
puts "Removing duplicates"
email_array = email_array.uniq
sizeb = email_array.length
size = sizea - sizeb 
puts "#{size} duplicate emails removed"
size = email_array.length
#puts size
i=0
bad_count = 0
while (i<size) do
	#puts email_array[i]
	if !(/\b[a-zA-Z0-9!#$%&'*+-\/=?^_`.{|}~]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b/ =~ email_array[i])
		puts "removing bad address: #{email_array[i].inspect}"
		email_array.delete_at(i)
		bad_count = bad_count + 1
		i=i-1 #delete_at() alters size of array and shifts indexing. account for this here
		size=size-1
	end
	#puts i
	i=i+1
end

size = email_array.length
puts "#{bad_count} total invalid address removed, new CSV size: #{size}"
#puts email_array.inspect
email_array.insert(0,"email")
#puts email_array.inspect
csv_write("valid_emails.csv", email_array.flatten, "email")
puts "Valid emails written to 'valid_emails.csv'"
