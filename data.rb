#!/usr/bin/env ruby

require 'pg'
require './lib/helper.rb'

conn = connect_to_db()
result = get_public_bodies(conn)
result.each do |row|
	print row
end