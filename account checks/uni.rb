# ruby uni.rb
# Make some quick checks on uni link set up, takes user inputs after begining script
# 1 Create an email link whitelabel
# 2 Set up a SSL certificate for the email link whitelabel
# 3 Upload JSON files (Association file for iOS and Asset links file for Android) to your domain and host over HTTPS
# 4 Resolve SendGrid click tracking links
# 5 Prepare your app by adding an Entitlement (iOS) or Intent (Android), and code to consume links
# 6 Flag your links as universal by adding the attribute “universal=true” to links in your HTML

############
require 'httparty'
require 'json'
#Addapted from https://github.com/sendgrid/supporter-backend/blob/7a12a20ab1057b7b9ef757759ab779e4f4f92067/components/ssl_click_verifier/lib/ssl_click_verifier/verifier.rb
###################
require 'net/http'
require 'net/https'
require 'uri'
require 'net/dns'

class SSLClickVerifier
  def verify(domain)
    valid_domain_check = self.validate_domain_syntax domain
   #puts $syntaxstatus
   #puts @syntaxnotes
   unless $syntaxstatus == "PASS"
      return valid_domain_check
    end

    cname_check = self.check_cname domain
    status = $cnamestatus

    ssl_chain_check = self.check_ssl_chain domain
    status = if ($sslstatus == "FAIL" && $cnamestatus == "PASS") then $sslstatus else $cnamestatus end
    notes = $cnamenotes + "\n" + $sslnotes + "\n"

    #SSLClickVerifier::Result.new do | r |
     $status = status 
     $notes = notes 
   # end
  end
def validate_domain_syntax(domain)
    status = "FAIL"
    notes = "FAIL: Domain is in an invalid format. Please ensure that it is formatted like `subdomain.domain.com` (do not put in the 'http://' or 'https://' part.<br>"
    if /^(([^\/ \n\r]+\.)([^\/ \n\r]+\.)+(\S+))$/i.match(domain)
      status = "PASS"
      notes = "PASS: Domain is in the correct format.<br>"
    end

   # SSLClickVerifier::Result.new do | r |
   $syntaxstatus = status
   $syntaxnotes = notes 
   # end
  end

  def check_cname(domain)
    test_status = "NEUTRAL"
    test_notes = "WARNING: Domain does not have a CNAME. If the domain uses a CDN that terminates the SSL connection, everything should be fine. You'll want to verify that a click tracking link from their domain over HTTPS goes through without any certificate errors.<br>"

    begin
      packet = Net::DNS::Resolver.start(domain, Net::DNS::CNAME)
      packet.answer.each do | answer |
        if /sendgrid.net/i.match(answer.value)
          test_status = "FAIL"
          test_notes = "FAIL: Domain has a CNAME pointing to `sendgrid.net`. This will result in certificate failures. The customer will need to have the CNAME point to a CDN that can terminate the SSL connection and forward the request to SendGrid. https://sendgrid.com/docs/Classroom/Track/Clicks/clicktracking_ssl.html<br>"
          break
        elsif /fastly/i.match(answer.value) or /cloudflare/i.match(result.value)
          test_status = "PASS"
          test_notes = "PASS: Domain has a CNAME pointing to Fastly or CloudFlare.<br>"
          break
        else
          test_status = "NEUTRAL"
          test_notes = "WARNING: Domain has a CNAME pointing to an unknown domain (#{answer.value}). If this is a valid CDN that terminates the SSL connection, everything should be fine. You'll want to verify that a click tracking link from their domain over HTTPS goes through without any certificate errors.<br>"
          break
        end
      end
    rescue
      test_status = "NEUTRAL"
      test_notes = "WARNING: The provided domain did not respond to a DNS check.<br>"
    end

  #  SSLClickVerifier::Result.new do | r |
   $cnamestatus = test_status
   $cnamenotes = test_notes
   # end
  end

  def check_ssl_chain(domain)
    status = "FAIL"
    notes = "FAIL: We did not get a 200 response back from the test 'https' click tracking link.<br>"
    begin
      url = URI.parse "https://#{domain}/wf/click?upn=V"
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.verify_depth = 5
      request = Net::HTTP::Get.new(url.path)
      begin
        response = http.request(request)
      rescue Zlib::DataError
        begin
          request['Accept-Encoding'] = 'identity'
          response = http.request(request)
        rescue
          status = "FAIL"
          notes = "FAIL: The user is returning improperly encoded headers that are unreadable by browsers and/or basic http clients.<br>"
        end
      end
      unless response.nil? or response.code.nil? or response.code.to_i >= 300
        status = "PASS"
        notes = "PASS: A test 'https' click tracking link returned a #{response.code} without any SSL Certificate errors.<br>"
      end
    rescue OpenSSL::SSL::SSLError
      notes = "FAIL: A certificate error was present on a test 'https://#{domain}' link. This most likely points to an issue with their CDN configuration not terminating the SSL session correctly. See https://sendgrid.com/docs/Classroom/Track/Clicks/clicktracking_ssl.html for more information.<br>"
    rescue SocketError => e
      status = "FAIL"
      notes = "FAIL: The provided domain does not appear to be valid, as it currently does not have any DNS records. Double check the spelling and try again. You can also try digging for an A record at that domain to ensure it's valid.<br>"
    end

  #  SSLClickVerifier::Result.new do | r |
  $sslstatus = status
  $sslnotes = notes
  #  end
  end
end
###################
# check for valid API call to get Link Branding details
response_code = "999"
while !(response_code == "200")
	# Get token
	puts "Please enter a authentication token (not Basic or Bearer authentication): "
	token = gets.chomp
	#get Link branding ID
	puts "Please enter the Link Branding ID"
	lb_id = gets.chomp
	uri = "https://api.sendgrid.com/v3/whitelabel/links/#{lb_id}"
	# API call to get LB validity and records.
	response = HTTParty.get(uri, headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
	# response code
	response_code = response.code.to_s
	if !(response_code == "200")
		puts "Error finding Link Brand: "
		puts "'#{response_code}' - #{response}"
	end 
end
# Check validity of Link Brand
body = JSON.parse(response.to_s)
is_valid = body["valid"].to_s
if (is_valid == "true")
	host = body["dns"]["domain_cname"]["host"]
	puts "Found Link brand for '#{host}'"
	# Check for SSL certs
	puts "Checking for SSL certificate..."
	#ssluri = "https://#{host}"
	#puts ssluri
	ssl_verify = SSLClickVerifier.new()
	result = ssl_verify.verify(host)
	#puts result
	valid_notes= "This Link Brand is valid!"
else
	puts "This Link Brand is not valid. Please validate before moving forward with Universal Link set up!"
	valid_notes = "This Link Brand is not valid. Please validate before moving forward with Universal Link set up!"
end
# check for association files IF SSL PASSES
if ($sslstatus == "PASS")
	puts "Checking for JSON files..."
	apple1url = "https://#{host}/apple-app-site-association"
	apple2url = "https://#{host}/.well-known/apple-app-site-association"
	androidurl = "https://#{host}/.well-known/assetlinks.json"

	apple1response = HTTParty.get(apple1url)
	apple1response_code = apple1response.code.to_s
	if(/2\d*/ =~ apple1response_code)
		bodyapple1 = JSON.parse(apple1response.to_s)
		#puts "Success! Found assocation files at '#{apple1url}'"
	    apple1_notes = "Success! Found assocation files at '#{apple1url}' \n"
		pathapple1 = bodyapple1["applinks"]["details"].to_s
		if !(/.*\"appID\".*\"paths\".*\"\/uni\/\*.*/ =~ pathapple1)
			#puts "WARNING: Associations file at #{apple1url} may be formated incorrectly"
	        apple1_notes = apple1_notes + "<br>WARNING: Associations file at #{apple1url} may be formated incorrectly \n"
		end
	else
		puts "Failed to find assocation files at '#{apple1url}'"
	    apple1_notes = "Failed to find assocation files at '#{apple1url}' \n"
	end

	apple2response = HTTParty.get(apple2url)
	apple2response_code =apple2response.code.to_s
	if(/2\d*/ =~ apple2response_code)
		bodyapple2 = JSON.parse(apple2response.to_s)
		#puts bodyapple2
		#puts "Success! Found assocation files at '#{apple2url}'"
	    apple2_notes = "Success! Found assocation files at '#{apple2url}' \n"
		pathapple2 = bodyapple2["applinks"]["details"].to_s
		if !(/.*\"appID\".*\"paths\".*\"\/uni\/\*.*/ =~ pathapple2)
			#puts "WARNING: Associations file at #{apple2url} may be formated incorrectly"
	        apple2_notes = apple2_notes + "<br>WARNING: Associations file at #{apple2url} may be formated incorrectly \n"
		end

	else
		puts "Failed to find assocation files at '#{apple2url}'"
	    apple2_notes = "Failed to find assocation files at '#{apple2url}' \n"
	end
	################################
	androidresponse = HTTParty.get(androidurl)
	androidresponse_code = androidresponse.code.to_s
	if(/2\d*/ =~ androidresponse_code)
		bodyandroid = JSON.parse(androidresponse.to_s)
		#puts bodyandroid
		#puts "Success! Found assocation files at '#{androidurl}'"
	    android_notes = "Success! Found assocation files at '#{androidurl}' \n"
	else
		#puts "Failed to find assocation files at '#{androidurl}'"
	    android_notes = "Failed to find assocation files at '#{androidurl}' \n"
	end

	json_notes = apple1_notes + "<br>" + apple2_notes + "<br>" + android_notes
else
	json_notes = "SSL has failed"
end
# flags for report:
# valid LB
# SSL/warnings
# JSON files/warnings
# always in report:
# remind about resolving links on app
# code to consume links
# taging links

#get username and UID

user = HTTParty.get("https://api.sendgrid.com/v3/user/username", headers: {"Authorization" => "token #{token}", "Content-Type" => "application/json"})
userbody = JSON.parse(user.to_s)
uid = userbody["user_id"]
username = userbody["username"]

html = "<!DOCTYPE html> <html> <head> <title>Uni Links Test</title> <meta name=\"viewport\" content=\"width=device-width\" /> <style> body {font-family:\"Verdana\";font-weight:normal;font-size: .7em;color:black;} p {font-family:\"Verdana\";font-weight:normal;color:black;margin-top: -5px} b {font-family:\"Verdana\";font-weight:bold;color:black;margin-top: -5px} H1 { font-family:\"Verdana\";font-weight:normal;font-size:18pt;color:red } H2 { font-family:\"Verdana\";font-weight:normal;font-size:14pt;color:maroon } pre {font-family:\"Consolas\",\"Lucida Console\",Monospace;font-size:11pt;margin:0;padding:0.5em;line-height:14pt} .marker {font-weight: bold; color: black;text-decoration: none;} .version {color: gray;} .error {margin-bottom: 10px;} .expandable { text-decoration:underline; font-weight:bold; color:navy; cursor:hand; } @media screen and (max-width: 639px) {pre { width: 440px; overflow: auto; white-space: pre-wrap; word-wrap: break-word; } } @media screen and (max-width: 479px) {pre { width: 280px; } } </style> </head> <body bgcolor=\"white\"> <span> <H1>Universal links audit for user <b> #{username} | #{uid}</b> <hr width=100% size=1 color=silver> </H1> <h2> <i>Link Brand</i> </h2> </span> <font face=\"Arial, Helvetica, Geneva, SunSans-Regular, sans-serif \"> <b> Valid: </b> Link Brand (#{host}) #{valid_notes} <br> <b> SSL: </b> #{result} <h2> <i>JSON association Files</i> </h2> </span> <font face=\"Arial, Helvetica, Geneva, SunSans-Regular, sans-serif \"> #{json_notes} <br> <h2> <i>Prepare APP</i> </h2> </span> <font face=\"Arial, Helvetica, Geneva, SunSans-Regular, sans-serif \"> Confirm with user that their APP is set up to <a target=_blank href=\"https://sendgrid.com/docs/ui/sending-email/universal-links/#resolving-sendgrid-click-tracking-links\">resolve SendGrid click tracking links</a> <br> Confirm with user that their APP is prepared by having an <a target=_blank href=\"https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html\">Entitlement (iOS)</a> or <a target=_blank href=\"https://developers.google.com/digital-asset-links/v1/getting-started\">Intent (Android)</a> added, and code to consume links. <h2> <i>Tagging Links</i> </h2> </span> <font face=\"Arial, Helvetica, Geneva, SunSans-Regular, sans-serif \">  Use this <a target=_blank href=\"https://splunk.sendgrid.net/en-US/app/search/search?earliest=-14d%40d&latest=now&q=search%20userid%3D%22#{uid}%22%20%22links.universal%22!%3D0&display.page.search.mode=smart&dispatch.sample_ratio=1&sid=1544810065.601263_E9F91CC7-DC87-4C7E-938A-65D468266A30\">splunk search</a> <code> userid=\"#{uid} \"links.universal\"!=0</code> to see if user is tagging link in HTML with the code: <code> &lt;a href=&quot;LINK TO APP&quot; universal=&quot;true&quot;&gt;Link to your app!&lt;/a> <\code> <br> </body> </html>"
out_file = File.new("#{username}.html", "w")
out_file.puts(html)
puts "Report written to #{username}.html. Open in a web Browser"
