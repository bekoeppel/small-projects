#!/usr/bin/env ruby

# Source: https://moocode.com/posts/5-simple-two-factor-ssh-authentication-with-google-authenticator

require 'rubygems'
require 'rotp'
 
secret = ROTP::Base32.random_base32
data = "otpauth://totp/#{`hostname -s`.strip}?secret=#{secret}"
url = "https://chart.googleapis.com/chart?chs=200x200&chld=M|0&cht=qr&chl=#{data}"
 
puts "Your secret key is: #{secret}"
puts url
