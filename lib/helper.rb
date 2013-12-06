require 'json'
require 'csv'

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
	public_bodies = conn.exec( "SELECT name, short_name, request_email, home_page FROM public_bodies" ).to_a
    return {
    	'organismos' => public_bodies
    }	
end

def write_to_disk(data, output_path)
	write_to_json(data, output_path + '.json')
	write_csv(data, output_path + '.csv')
end

def write_csv(data, output_path)
	CSV.open(output_path, "wb") do |csv|
		csv << data['organismos'].first.keys
		data['organismos'].each do |org|
		  csv << org.values
  	    end
	end
	print "Escribio los datos en csv a %s\n" % output_path
end

def write_to_json(data, output_path)
	File.open(output_path,"w") do |f|
  		f.write(data.to_json)
	end
	print "Escribio los datos en json a %s\n" % output_path
end
