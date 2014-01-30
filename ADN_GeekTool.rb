#!/usr/bin/env ruby
# encoding: utf-8
# Get App.net user informations for GeekTool
# © 2014 Code by Eric Dejonckheere (@ericd)
# Idea and comments by Andrew Thornton (@andrewthornton), with help from Charl Dunois (@charl)

## First, you must get a token from your App.net account (https://account.app.net/developer/apps/) and paste it in the YOUR_TOKEN constant below (between the single quotes)

YOUR_TOKEN = ''

## You also may have to run 'gem install json' before using this script

require 'json'
require 'net/http'
require 'open-uri'
require 'openssl'

BASE_URL = "https://alpha-api.app.net/"
USERS_URL = BASE_URL + "stream/0/users/"
TOKEN_URL = BASE_URL + "stream/0/token/"


# "include_html" and "include_annotations" are options that can be turned off or on, to do so change the value: 0 for false, 1 for true

@including = "&include_html=1&include_annotations=0"

# Replace "me" by "@anyusername" to get infos about @anyusername

@user_handle = "me"

# We build the complete URL

@user_info_url = USERS_URL + "#{@user_handle}/?access_token=#{YOUR_TOKEN}#{@including}"

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

# Method to detect the current "Posts achievement club"

def get_current_club(posts)
   clubs = {500=>"RollClub", 1000=>"CrumpetClub", 2000=>"BitesizeCookieClub", 2600=>"CrunchClub", 3000=>"MysteryScienceClub", 5000=>"LDRClub", 8088=>"IBMPCClub", 10000=>"CookieClub", 11000=>"SpinalTapClub", 20000=>"BreakfastClub", 24000=>"CaratClub", 25000=>"PeshawarClub", 30000=>"MileHighClub", 31416=>"PiClub", 42000=>"TowelClub", 47000=>"HitmanClub", 50000=>"BaconClub", 57000=>"BrowncoatClub", 64000=>"CommodoreClub", 68000=>"MotorolaClub", 76000=>"TromboneClub", 80211=>"WiFiClub", 90000=>"PajamaClub", 100000=>"TowerOfBabble", 128000=>"MacClub", 144000=>"TwitterLeaverClub", 200000=>"GetALifeNoSrslyClub"}
   min_count = clubs.keys[0]
   if posts >= min_count
      clubs.each_cons(2) do |(prev_key, prev_value), (next_key, next_value)|
         if posts >= prev_key && posts < next_key
            return "Member of the ADN #{prev_value}."
            break
         end  
      end
   else
      # only if posts number is less than the first club
      puts "Still #{min_count - posts} posts to the #{clubs.values[0]}..."
   end
end

# Method to get the File Info JSON response from ADN

def get_file_storage()
   adn_response = connect(TOKEN_URL)
   abort("Error: #{adn_response.inspect}") unless adn_response.code == "200"
   resp = JSON.parse(adn_response.body)
   abort("ERROR: #{resp['meta']}") unless resp['meta']['code'] == 200
   file_storage = resp['data']['storage']
   return file_storage['available'], file_storage['used']
end

# Return the file size with a readable style.
GIGA_SIZE = 1073741824.0
MEGA_SIZE = 1048576.0
KILO_SIZE = 1024.0
def readable_file_size(size)
   case
   when size == 1 then "1 Byte"
   when size < KILO_SIZE then "#{size} Bytes"
   when size < MEGA_SIZE then "#{size.to_s.slice(0,3).to_f / 10} KB"
   when size < GIGA_SIZE then "#{size.to_s.slice(0,3).to_f / 10} MB"
   else "#{size.to_s.slice(0,3).to_f / 10} GB"
   end
end

# Return the percentage of file storage used

def get_storage_percentage(total_storage = 0, storage = 0)
   total_storage = total_storage.to_s.slice(0,3).to_f / 10 unless total_storage == 0
   storage = storage.to_s.slice(0,3).to_f / 10 unless storage == 0

   case
   when total_storage == storage then 100
   when storage == 0 then 0
   when total_storage > storage
      ((storage / total_storage) * 100.0).round(1)
   when total_storage < storage
      ((storage / total_storage) * 0.1).round(1)
   end
end

## Get the JSON then focus on the 'data' part

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
 
puts "\e[1;37mCurrent username:\e[0m #{username}" 
puts "\e[1;37mMember number:\e[0m #{id}\n\n"
puts "\e[1;37mCurrent Bio:\e[0m \n\n#{bio}\n\n"
puts "\e[1;37mFollowers:\e[0m #{followers}"
puts "\e[1;37mPosts:\e[0m #{posts} - " + get_current_club(posts)
puts "\e[1;37mStars:\e[0m #{stars}"
puts "\e[1;37mVerified Domain:\e[0m http://#{domain}" unless domain == ""

# Display amount of file storage used

storage_available, storage_used = get_file_storage()
total_storage = storage_available + storage_used
puts "\n\e[1;37mFile Storage:\e[0m #{readable_file_size(total_storage)}"
puts "\e[1;37m-Used:\e[0m #{readable_file_size(storage_used)} (#{get_storage_percentage(total_storage, storage_used)}%)"
puts "\e[1;37m-Available:\e[0m #{readable_file_size(storage_available)} (#{get_storage_percentage(total_storage, storage_available)}%)"
