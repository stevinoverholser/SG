# Generate a SendGrid cURL or JSON payload based on user input
# run "ruby send_gen.rb" and follow in consol prompts
############
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

puts "Lets build a SendGrid v3 API mail send cURL call or JSON payload!"

# get a To addresses
to = "nil"
to_p = ""
moreAddresses = "y"
toCount = 0
puts "Enter To address or a number (less than 1000) of sink addressses to generate: "
to = gets.chomp
toInt = to.to_i
while (!(/\S*@\S*[.]\S*/ =~ to) && !(toInt >= 1 && toInt <= 1000)) ## add regex validation for the Int, and use that to populate a flag to then trigger later. "if it's a number, generate"/"if it's a string..."
  puts "Invalid input, please enter valid address or integer between 1-1000: "
  to = gets.chomp
  toInt = to.to_i
end 
if (/\S*@\S*[.]\S*/ =~ to) ##use a function to validate the address format, so that you  can be more DRY, instead of the deep logic below
  puts "To: #{to}"
  while (moreAddresses == "y" || moreAddresses == "yes") do
    toCount = toCount + 1
    while !(/\S*@\S*[.]\S*/ =~ to) do
      if (toCount > 1)
        puts "Enter To address: "
        to = gets.chomp
      end 
      if /\S*@\S*[.]\S*/ =~ to
        puts "To: #{to}"
      else
        puts "Invalid address, please enter address in format name@domain.com"
      end
    end
    puts "Add more To addresses? (y/n):" ##if they enter a null, move forward
    moreAddresses = gets.chomp
    if !(moreAddresses == "y" || moreAddresses == "n" || moreAddresses == "yes" || moreAddresses == "no")
      puts "Please enter either 'y' or 'n'"
      while !(moreAddresses == "y" || moreAddresses == "n" || moreAddresses == "yes" || moreAddresses == "no") do
        puts "Add more To addresses? (y/n):"
        moreAddresses = gets.chomp
      end
    end
    # "{\"email\": \"#{to}\"}, {\"email\": \"string (required)\"}" 
    if toCount == 1
        to_p = "{\"email\": \"#{to}\"}"
        to = "nil"
    else
      to_p = "{\"email\": \"#{to}\"} , " + to_p 
      to = "nil"
    end
  end
else
  if (toInt >= 1 && toInt <= 1000)
  i = 1
  while (i <= toInt) do
    if (i == 1)
      to="testing#{i.to_s}@sink.sendgrid.net"
      to_p = "{\"email\": \"#{to}\"}"
        to = "nil"
        i= i+1
    else
      to="testing#{i.to_s}@sink.sendgrid.net"
      to_p = "{\"email\": \"#{to}\"} , " + to_p
      to = "nil"
      i = i+1
    end
  end
  end
end
# get a From address
from = "nil" 
while !(/\S*@\S*[.]\S*/ =~ from) do
  from = "default@sink.sendgrid.net"
  puts "Enter From address: " 
  from = gets.chomp
  if /\S*@\S*[.]\S*/ =~ from
    puts "From: #{from}"
  else
    puts "Invalid address, please enter address in format name@domain.com"
  end
end
subject = "defult"
puts "Enter Subject line: " 
subject = gets.chomp
puts "Subject: #{subject}"
subject = subject.gsub(/\"/, "\\\"")
puts subject
puts "Enter plain text body content: " 
content = gets.chomp
content = content.gsub(/\"/, "\\\"")
puts "Type 'now' to send now or enter EPOCH timestamp: " 
send_at = gets.chomp
send_at_i = send_at.to_i
# if not "now" or time is less than now or greater than 72 hours.
while (send_at != "now" && (send_at_i < Time.now.to_i || send_at_i >= (Time.now.to_i + 259200))) do
  if  send_at_i >= (Time.now.to_i + 259200)
    puts "Can not schedule more than 72 hours in advance. please enter a value less than #{(Time.now.to_i + 259200)}"
    send_at = gets.chomp
    send_at_i = send_at.to_i
  else
    if (send_at == nil)
      puts "No input, setting send_at to now"
      send_at="now"
    else
      puts "Invalid input please 'now' to send now or enter EPOCH timestamp:"
      send_at = gets.chomp
      send_at_i = send_at.to_i
    end
  end
end
if (send_at == "now")
  #Build Payload
  payload = "{\"personalizations\": [{\"to\": [#{to_p} ] } ], \"from\": {\"email\": \"#{from}\"}, \"subject\": \"#{subject}\", \"content\": [{\"type\": \"text/plain\", \"value\": \"#{content}\"} ] }"
  #puts "Here is you v3 payload (already copied to your clipboard): "
  # print payload an load to clipboard
else
  #Build Payload
  payload = "{\"personalizations\": [{\"to\": [#{to_p} ] } ], \"from\": {\"email\": \"#{from}\"}, \"subject\": \"#{subject}\", \"content\": [{\"type\": \"text/plain\", \"value\": \"#{content}\"} ], \"send_at\": \"#{send_at}\" }"
  #puts "Here is you v3 payload (already copied to your clipboard): "
  # print payload an load to clipboard
end

puts "Generate a JSON payload, a full cURL call, or send message? Please input 'json', 'curl' or 'send' respectivly: "
type = gets.chomp
while (type != "json" && type != "curl" && type != "send") ##try an if/else here
  puts "Invalid input, please only enter 'json' for a JSON payload or 'curl' for a formatted cURL call: "
  type = gets.chomp
end

if (type == "curl")
  puts "Enter API key: "
  token = gets.chomp
  puts "Do you want this cURL call copied to your clipboard? (enter 'y' to copy clipboard): "
  copy = gets.chomp
  cURL = "curl  -v --request POST \
    --url https://api.sendgrid.com/v3/mail/send \
    --header 'authorization: Bearer #{token}' \
    --header 'content-type: application/json' \
    --data '#{payload}'"
   puts  "Here is your v3 cURL call: " 
  # build cURL
  puts "#{cURL}"
  if(copy =="y")
    pbcopy(cURL)
  end 
end

if (type == "json")
  puts "Do you want this JSON payload copied to your clipboard? (enter 'y' to copy clipboard): " 
  copy = gets.chomp
  puts "Here is your v3 payload: " 
  puts "#{payload}"
  if(copy =="y")
    pbcopy(payload)
  end
end

if (type == "send")
  puts "Enter API key: "
  token = gets.chomp
  puts "attempting to send message.."
  response = HTTParty.post(
      'https://api.sendgrid.com/v3/mail/send', 
      body: payload,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json"
      }
    )
  puts response
end
