# subuser.rb - create subuser- apikey -template -webhook integration
require 'httparty'
require 'json'
# methods for adding to users clipboard
def pbcopy(input)
    str = input.to_s
    IO.popen('pbcopy', 'w') { |f| f << str }
    str
  end
  
  def pbpaste
    `pbpaste`
  end

puts "Enter Subuser Username (will append with \"-StevinDemo\"):"
brand = gets.chomp 
username = brand + "-StevinDemo"
token = "<<apikey>>"

# Create Subuser

payload = "{\"username\": \"#{username}\", \"email\": \"stevinoverholser@gmail.com\", \"password\": \"2129Rosecrance!(($\", \"ips\": [\"168.245.60.69\"] }"
response = HTTParty.post(
      'https://api.sendgrid.com/v3/subusers', 
      body: payload,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json"
      }
    )
if response.code == 201
    puts "Subsuer Created"
else
    puts "Subuser creation failed with error:"
    puts "#{response.code} - #{response.body}"
    exit
end
# Assign Authentication

domain_id = "1135337"
link_id = "1006414"
puts "Assigning Authentication"

# domain auth

payload = "{\"username\": \"#{username}\"}"
uri = "https://api.sendgrid.com/v3/whitelabel/domains/#{domain_id}/subuser"
response = HTTParty.post(
      uri, 
      body: payload,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json"
      }
    )
if response.code == 201
    puts "Domain authentication assigned"
else
    puts "Domain authentication assignment failed with error:"
    puts "#{response.code} - #{response.body}"
    exit
end

# link brand

payload = "{\"username\": \"#{username}\"}"
uri = "https://api.sendgrid.com/v3/whitelabel/links/#{link_id}/subuser"
response = HTTParty.post(
      uri, 
      body: payload,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json"
      }
    )
if response.code == 201
    puts "Link branding assigned"
else
    puts "Link branding assignment failed with error:"
    puts "#{response.code} - #{response.body}"
    exit
end

# Create Design

# get master template from parent

master_template_id = "eb820f3f-7826-429d-ba5f-f5ca96dcfb52"
uri = "https://api.sendgrid.com/v3//designs/#{master_template_id}"
response = HTTParty.get(
      uri, 
      body: payload,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json"
      }
    )
if response.code == 200
    design_html = response["html_content"]
    puts "Master design found"
else
    puts "Master design retrival failed with error:"
    puts "#{response.code} - #{response.body}"
    exit
end

# create design 

payload = "{\"name\": \"#{brand} Design\", \"html_content\": " + design_html.to_json + ", \"generate_plain_content\": true, \"subject\": \"Hello {{first_name}}\", \"editor\": \"design\", \"categories\": [\"new_mail_stream\"] }"
uri = "https://api.sendgrid.com/v3/designs"
response = HTTParty.post(
      uri, 
      body: payload,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json",
        "on-behalf-of" => "#{username}"
      }
    )
if response.code == 201
    design_id = response["id"]
    puts "Design #{design_id} created"
else
    puts "Design creation failed with error:"
    puts "#{response.code} - #{response.body}"
    exit
end

# Create Template/Version

# template

payload = "{\"name\": \"#{brand} Example\", \"generation\": \"dynamic\"}"
uri = "https://api.sendgrid.com/v3/templates"
response = HTTParty.post(
      uri, 
      body: payload,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json",
        "on-behalf-of" => "#{username}"
      }
    )
if response.code == 201
    template_id = response["id"]
    puts "Template #{template_id} created"
else
    puts "Template creation failed with error:"
    puts "#{response.code} - #{response.body}"
    exit
end

# version

payload = "{\"template_id\": \"#{template_id}\", \"active\": 1, \"name\": \"V1\", \"html_content\": "  + design_html.to_json + ", \"subject\": \"Hello {{first_name}}\", \"test_data\": \"{\\\"first_name\\\": \\\"Stevin\\\", \\\"new_user\\\" : \\\"true\\\", \\\"brand\\\" : \\\"#{brand}\\\", \\\"url\\\" : \\\"http:\\\/\\\/sendgrid.com\\\"}\"}"
uri = "https://api.sendgrid.com/v3/templates/#{template_id}/versions"
response = HTTParty.post(
      uri, 
      body: payload,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json",
        "on-behalf-of" => "#{username}"
      }
    )
if response.code == 201
    version_id = response["id"]
    puts "Version #{version_id} created"
else
    puts "Template version creation failed with error:"
    puts "#{response.code} - #{response.body}"
    exit
end

# Create API key

payload = "{\"name\": \"#{brand} API Key\", \"scopes\": [\"mail.send\", \"user.username.read\"] }"
uri = "https://api.sendgrid.com/v3/api_keys"
response = HTTParty.post(
      uri, 
      body: payload,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json",
        "on-behalf-of" => "#{username}"
      }
    )
if response.code == 201
    api_key = response["api_key"]
    puts "Mail Send API Key created: #{api_key}"
    pbcopy(api_key)
else
    puts "Mail Send API Key creation failed with error:"
    puts "#{response.code} - #{response.body}"
    exit
end

# create endpoint

payload = "{\"enabled\": true, \"url\": \"http:\/\/stevin.ngrok.io\/\", \"group_resubscribe\": true, \"delivered\": true, \"group_unsubscribe\": true, \"spam_report\": true, \"bounce\": true, \"deferred\": true, \"unsubscribe\": true, \"processed\": true, \"open\": true, \"click\": true, \"dropped\": true }"
uri = "https://api.sendgrid.com/v3/user/webhooks/event/settings"
response = HTTParty.patch(
      uri, 
      body: payload,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json",
        "on-behalf-of" => "#{username}"
      }
    )
if response.code == 200
    puts "Event Webhook created"
else
    puts "Event Webhook creation failed with error:"
    puts "#{response.code} - #{response.body}"
    exit
end
