#!/usr/bin/env ruby

require 'pg'
require './lib/helper.rb'

conn = connect_to_db()

# public_bodies = [ {name, short_name, request_email, home_page} ] 
public_bodies = get_public_bodies(conn)
write_to_json(public_bodies, 'data/public_bodies.json')