#!/usr/bin/env ruby

require 'pg'
require './lib/helper.rb'

conn = connect_to_db()

# public_bodies = [ {name, short_name, request_email, home_page} ] 
public_bodies = get_public_bodies(conn)
write_to_disk(public_bodies, 'data/organismos_publicos')

info_requests = get_info_requests(conn)
write_to_disk(info_requests, 'data/pedidos')