#!/usr/bin/env ruby
# encoding: utf-8
# Get App.net user informations for GeekTool
# © 2014 by Eric Dejonckheere (@ericd) 
# Additional code by Donny Davis (@donnywdavis)
# Original idea and comments by Andrew Thornton (@andrewthornton), with help from Charl Dunois (@charl)

# CONFIGURATION

## First, you must get a token from your App.net account (https://account.app.net/developer/apps/) and paste it in the YOUR_TOKEN constant below (between the single quotes)

YOUR_TOKEN = ''

## You also may have to run 'gem install json' before using this script

require 'json'
require 'net/http'
require 'open-uri'
require 'openssl'

# URLs

BASE_URL = "https://alpha-api.app.net/"
USERS_URL = BASE_URL + "stream/0/users/"
TOKEN_URL = BASE_URL + "stream/0/token/"

## "include_html" and "include_annotations" are options that can be turned off or on, to do so change the value: 0 for false, 1 for true

@including = "&include_html=1&include_annotations=0"

## Replace "me" by "@anyusername" to get infos about @anyusername

@user_handle = "me"

## We build the complete URL

@user_info_url = USERS_URL + "#{@user_handle}/?access_token=#{YOUR_TOKEN}#{@including}"

# METHODS

## HTTP method to connect to the ADN API

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

## Method to get the User Info JSON response from ADN and check for errors

def get_infos
   adn_response = connect(@user_info_url)
   abort("ERROR: #{adn_response.inspect}") unless adn_response.code == "200"
   resp = JSON.parse(adn_response.body)
   abort("ERROR: #{resp['meta']}") unless resp['meta']['code'] == 200
   return resp
end

## Method to detect the current "Posts achievement club"

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
      return "Still #{min_count - posts} posts to the #{clubs.values[0]}..."
   end
end

## Method to get the File Info JSON response from ADN

def get_file_storage()
   adn_response = connect(TOKEN_URL)
   abort("Error: #{adn_response.inspect}") unless adn_response.code == "200"
   resp = JSON.parse(adn_response.body)
   abort("ERROR: #{resp['meta']}") unless resp['meta']['code'] == 200
   file_storage = resp['data']['storage']
   return file_storage['available'], file_storage['used']
end

## Return the file size with a readable style

GIGABYTE = 1073741824.0
MEGABYTE = 1048576.0
KILOBYTE = 1024.0
def readable_file_size(size)
   case
   when size == 1 then "1 Byte"
   when size < KILOBYTE then "#{size} Bytes"
   when size < MEGABYTE then "#{size.to_s.slice(0, get_slice_value(size)).to_f / 10} KB"
   when size < GIGABYTE then "#{size.to_s.slice(0, get_slice_value(size)).to_f / 10} MB"
   else "#{size.to_s.slice(0, get_slice_value(size)).to_f / 10} GB"
   end
end

# Get the number of characters to substring out of the size

def get_slice_value(size)
   case 
   when size >= KILOBYTE && size < MEGABYTE
      if size < 100000 then slice_value = 3
      elsif size >= 100000 then slice_value =4
      end
   when size >= MEGABYTE && size < GIGABYTE
      if size < 10000000 then slice_value = 2
      elsif size < 100000000 then slice_value = 3
      elsif size >= 100000000 then slice_value = 4
      end
   when size >= GIGABYTE
      slice_value = 3
   end
end

# We extend the Ruby String class to get a few convenient coloring methods for text output

## Just apply the method to your text like this: "text".bold

class String
    def bold
        "\033[1m#{self}\033[22m" 
    end
    def reverse_color
        "\033[7m#{self}\033[27m" 
    end
    def red
        "\033[31m#{self}\033[0m" 
    end
    def green
        "\033[32m#{self}\033[0m" 
    end
    def yellow
        "\033[33m#{self}\033[0m" 
    end
    def blue
        "\033[34m#{self}\033[0m" 
    end
end

# Get the JSON then focus on the 'data' part

infos = get_infos()
user_infos = infos['data']

# We are going to define what information we want to use from the JSON file that is returned from ADN

## Gets followers, counts and followers, counts is required as this is a count function
followers = user_infos['counts']['followers']

## Gets posts, counts and posts, counts is required as this is a count function 
posts = user_infos['counts']['posts']

## Gets stars, counts and posts, counts is required as this is a count function
stars = user_infos['counts']['stars']

## Grabs your current username
username = user_infos['username']

## Grabs your current bio and displays it as text, tried to print the HTML version but geektool didn't like it (creates an empty string if no text)
bio = user_infos['description']['text'] || ""

## Grabs your verified domain (creates an empty string if no domain)
domain = user_infos['verified_domain'] || ""

## Gets your member number 
id = user_infos['id']

# The values below are going to take the information we defined above and display it, you can re-arrange anything below and that is how it will appear on your desktop with GeekTool
 
puts "Current username: ".bold + "#{username}" 
puts "Member number: ".bold + "#{id}\n\n"
puts "Current Bio: ".bold + "\n\n#{bio}\n\n"
puts "Followers: ".bold + "#{followers}"
puts "Posts: ".bold + "#{posts} - " + get_current_club(posts)
puts "Stars: ".bold + "#{stars}"
puts "Verified Domain: ".bold + "http://#{domain}" unless domain == ""

# Display amount of file storage used

storage_available, storage_used = get_file_storage()
total_storage = storage_available + storage_used
puts "\nFile Storage: ".bold + "#{readable_file_size(total_storage)}"
puts "-Used: ".bold + "#{readable_file_size(storage_used)}"
puts "-Available: ".bold + "#{readable_file_size(storage_available)}"
