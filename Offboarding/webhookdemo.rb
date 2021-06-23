# webhookdemo.rb - Posts incoming webhook posts to a ngrok page
require 'rubygems'
require 'twilio-ruby'
require 'sinatra'
require 'httparty'
require 'cgi'
require 'json'

emailsyntax = "p1"
numbersyntax = "p1"

#./ngrok http -hostname=stevin.ngrok.io 4567
#Setting port
#set :port, 53
set :bind, '0.0.0.0'

$payload = "<style> code {
    background-color: #eee;
    border: 1px solid #999;
    display: block;
    padding: 20px;
  } </style>"

get '/' do
   "#{$payload}"
end 

post '/' do
    pretty = request.body.read.to_s
    pretty = pretty.gsub!(/,/ ,",<br>") 
    #pretty =  JSON.pretty_generate(JSON.parse(pretty))
    $payload = + $payload + "<code>" + pretty + "</code><br>"
    puts $payload
end

get '/clear' do
    $payload = "<style> code {
        background-color: #eee;
        border: 1px solid #999;
        display: block;
        padding: 20px;
      } </style>"
    redirect to ('/')
end 
