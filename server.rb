require 'rubygems'
require 'bundler/setup'
require 'sinatra'

get '/' do
  File.read 'index.html'
end

get '/oauth2callback' do
  File.read 'index.html'
end

# http://localhost:4567/oauth2callback#access_token=ya29.1.AADtN_W6680p2vYHr9M9udpkiQSMmVeYDvqZQcoqDAfaBKzvi2SZz3nTNW00U9I&token_type=Bearer&expires_in=3600