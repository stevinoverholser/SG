# Check DNS Availability
#require "resolv"
#Resolv::DNS.open do |dns|
#  ress = dns.getresources "stev.stevin.world", Resolv::DNS::Resource::IN::TXT
#  p ress.map { |r| [r.exchange.to_s, r.preference] }
#end

#cname  = system 'echo dig +short cname stev.stevin.world'
#puts cname.inspect


require 'open3'
puts "Domain: "
domain = gets.chomp
puts "Subdomain: "
subdomain = gets.chomp
as_cname1 = "#{subdomain}.#{domain}"
as_cname2 = "s1._domainkey.#{domain}"
as_cname3 = "s2._domainkey.#{domain}"
ms_mx = as_cname1
ms_txt1 = as_cname1
ms_txt2 = "m1._domainkey.#{domain}"

cname1 = true
cname2 = true
cname3 = true
mx = true
txt1 = true
txt2 = true

lb_cname = as_cname1

as = false
dkim = false
ms = false
lb = false

puts "\nQuerying '#{as_cname1}' CNAME"

stdout,stderr,status = Open3.capture3("dig +short cname #{as_cname1}")
STDERR.puts stderr
if status.success?
	result  = stdout.gsub("\n","")
  if (result == "")
  	#puts "No existing records found at #{as_cname1}"
  	cname1 = false
  else
  	puts "Found: CNAME '#{as_cname1}' --> '#{result}'"
  	cname1 = true
  end
else
  STDERR.puts "Error querying #{as_cname1}. Please try again."
  exit
end

puts "\nQuerying '#{as_cname2}' CNAME"

stdout,stderr,status = Open3.capture3("dig +short cname #{as_cname2}")
STDERR.puts stderr
if status.success?
	result  = stdout.gsub("\n","")
  if (result == "")
  	#puts "No existing records found at #{as_cname2}"
  	cname2 = false
  else
  	puts "Found: CNAME '#{as_cname2}' --> '#{result}'"
  	cname2 = true
  end
else
  STDERR.puts "Error querying #{as_cname2}. Please try again."
  exit
end

puts "\nQuerying '#{as_cname3}' CNAME"

stdout,stderr,status = Open3.capture3("dig +short cname #{as_cname3}")
STDERR.puts stderr
if status.success?
	result  = stdout.gsub("\n","")
  if (result == "")
  	#puts "No existing records found at #{as_cname3}"
  	cname3 = false
  else
  	puts "Found: CNAME '#{as_cname2}' --> '#{result}'"
  	cname3 = true
  end
else
  STDERR.puts "Error querying #{as_cname3}. Please try again."
  exit
end

puts "\nQuerying '#{ms_mx}' TXT"

stdout,stderr,status = Open3.capture3("dig +short mx #{ms_mx}")
STDERR.puts stderr
if status.success?
	result  = stdout.gsub("\n","")
  if (result == "")
  	#puts "No existing records found at #{ms_mx}"
  	mx = false
  else
  	puts "Found MX '#{ms_mx}' --> '#{result}'"
  	mx = true
  end
else
  STDERR.puts "Error querying #{ms_mx}. Please try again."
  exit
end

puts "\nQuerying '#{ms_txt1}' MX"

stdout,stderr,status = Open3.capture3("dig +short txt #{ms_txt1}")
STDERR.puts stderr
if status.success?
	result  = stdout.gsub("\n","")
  if (result == "")
  	#puts "No existing records found at #{ms_txt1}"
  	txt1 = false
  else
  	puts "Found TXT '#{ms_txt1}' --> '#{result}'"
  	txt1 = true
  end
else
  STDERR.puts "Error querying #{ms_txt1}. Please try again."
  exit
end

puts "\nQuerying '#{ms_txt2}' TXT"

stdout,stderr,status = Open3.capture3("dig +short txt #{ms_txt2}")
STDERR.puts stderr
if status.success?
	result  = stdout.gsub("\n","")
  if (result == "")
  	#puts "No existing records found at #{ms_txt2}"
  	txt2 = false
  else
  	puts "Found TXT '#{ms_txt2}' --> '#{result}'"
  	txt2 = true
  end
else
  STDERR.puts "Error querying #{ms_txt2}. Please try again."
  exit
end

if (cname1)
	#puts "Automatic Security not available. CNAME found at '#{as_cname1}'. Please pick another subdomain."
	as = false
else
	if (cname2 || cname3)
		as = true
		dkim = true
#		if (cname2 && !cname3)
#			#puts "CNAME at '#{as_cname2}'. Available with custom DKIM selectors!"
#		else
#			if (cname3 && !cname2)
#				#puts "CNAME at '#{as_cname3}'. Available with custom DKIM selectors!"
#			else
#				if (cname2 && cname3)
#					#puts "CNAME found at '#{as_cname2}' and '#{as_cname3}'. Available with custom DKIM selectors!"
#				end
#			end
#		end
	else
		#puts "Available for Automated Security."
		as = true
	end
end

if (mx || txt1)
	ms = false
	#puts "Manual Security not available. MX found at #{ms_mx}. Please pick another subdomain."
else
	if(txt2)
		ms=true
		dkim=true
		#puts "TXT at '#{ms_txt2}'. Available with custom DKIM selectors!"
	else
		ms = true
		#puts "Available for Manual Security."
	end
end

if (as)
	if (dkim)
		puts "Automatic Security available with custom DKIM selectors."
	else
		puts "Available for Automatic Security."
	end
else
	puts "Not available for Automatic Security. CNAME found at '#{as_cname1}'. Please pick another subdomain."
end

if (ms)
	if (dkim)
		puts "Manual Security available with custom DKIM selectors."
	else
		puts "Available for Manual Security."
	end
else
	puts "Not available for Manual Security. MX found at #{ms_mx}. Please pick another subdomain."
end

if (as && ms && !dkim)
	puts "Link Branding available."
else
	puts "Link Branding not available."
end 
