#!/usr/bin/env ruby
# encoding: utf-8
# Get App.net user informations for GeekTool
# Code by Eric Dejonckheere
# Idea and comments by Andrew Thornthon, with help from Charl Dunois

## First, you must get a token from your App.net account (check the settings in https://account.app.net/developer/apps/) and fill in the YOUR_TOKEN constant below (between the single quotes) with it

YOUR_TOKEN = ''

## You also may have to run 'gem install json' before using this script

require 'json'
require 'net/http'
require 'open-uri'
require 'openssl'

BASE_URL = "https://alpha-api.app.net/"
USERS_URL = BASE_URL + "stream/0/users/"

# "include_html" and "include_annotations" are options that can be turned off or on, to do so change the value: 0 for false, 1 for true

@including = "&include_html=1&include_annotations=0"

# We build the complete URL

@user_info_url = USERS_URL + "me/?access_token=#{YOUR_TOKEN}#{@including}"

# HTTP method to connect to the ADN API

def connect(url)
	uri = URI.parse(URI.encode(url))
	https = Net::HTTP.new(uri.host,uri.port)
	https.use_ssl = true
	https.verify_mode = OpenSSL::SSL::VERIFY_NONE
	request = Net::HTTP::Get.new(uri.request_uri)
	request["Authorization"] = "Bearer #{YOUR_TOKEN}"
	request["Content-Type"] = "application/json"
	https.request(request)
end

# Method to get the User Info JSON response from ADN and check for errors

def get_infos
	adn_response = connect(@user_info_url)
	abort("ERROR: #{adn_response.inspect}") unless adn_response.code == "200"
	resp = JSON.parse(adn_response.body)
	abort("ERROR: #{resp['meta']}") unless resp['meta']['code'] == 200
	return resp
end

# Get the JSON then focus on the 'data' part

infos = get_infos()
user_infos = infos['data']

## We are going to define what information we want to use from the JSON file that is returned from ADN

# Gets followers, counts and followers, counts is required as this is a count function
followers = user_infos['counts']['followers']

# Gets posts, counts and posts, counts is required as this is a count function 
posts = user_infos['counts']['posts']

# Gets stars, counts and posts, counts is required as this is a count function
stars = user_infos['counts']['stars']

# Grabs your current username
username = user_infos['username']

# Grabs your current bio and displays it as text, tried to print the HTML version but geektool didn't like it (creates an empty string if no text)
bio = user_infos['description']['text'] || ""

# Grabs your verified domain (creates an empty string if no domain)
domain = user_infos['verified_domain'] || ""

# Gets your member number 
id = user_infos['id']

## The values below are going to take the information we defined above and display it, you can re-arrange anything below and that is how it will appear on your desktop with GeekTool
 
puts "Current username: #{username}" 
puts "Member number: #{id}\n\n"
puts "Current Bio:\n\n#{bio}\n\n"
puts "Followers: #{followers}"
puts "Posts: #{posts}"
puts "Stars: #{stars}"
puts domain