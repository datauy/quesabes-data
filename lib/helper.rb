require 'json'

def connect_to_db
	return PG.connect( dbname: 'foi_production' )
end

## estadisticas

## pedidos
def get_pedidos
	pass
end

## public bodies
#    nombre, sigla, email, website
# public_bodies
#    name, short_name, request_email, home_page
def get_public_bodies(conn)
	return conn.exec( "SELECT name, short_name, request_email, home_page FROM public_bodies" ).to_a
end

def write_to_disk
	pass
end

def write_csv
	pass
end

def write_to_json(data, output_path)
	File.open(output_path,"w") do |f|
  		f.write(data.to_json)
	end
end
