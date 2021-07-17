#!/usr/bin/env ruby

require 'pg'
require './lib/helper.rb'
require 'date'

dir = "data/#{( Date.today - 1 ).strftime('%Y-%m')}/"
system 'mkdir', '-p', dir

conn = connect_to_db()

write_to_disk(get_public_bodies(conn), dir, "organismos_publicos")

write_to_disk(get_info_requests(conn), dir, "pedidos")

write_to_disk(get_requests_per_public_body(conn), dir, "cantidad_pedidos_por_organismo")
