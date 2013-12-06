#!/usr/bin/env ruby

require 'pg'
require './lib/helper.rb'

conn = connect_to_db()

write_to_disk(get_public_bodies(conn), 'data/organismos_publicos')

write_to_disk(get_info_requests(conn), 'data/pedidos')

write_to_disk(get_requests_per_public_body(conn), 'data/cantidad_pedidos_por_organismo')