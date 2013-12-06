require 'json'
require 'csv'

def connect_to_db
	return PG.connect( dbname: 'foi_production' )
end

## estadisticas

## pedidos
#    titulo, descripcion, fecha de realizado, organismo, estado, url
# info_requests
#    title, ..., created_at, public_body_id, described_state, url_title
# url will be http://quesabes.org/request/"url_title"
def get_info_requests(conn)
	sql_query = "SELECT info_requests.title, info_requests.created_at, info_requests.described_state, info_requests.url_title, 
	public_bodies.name
	FROM info_requests
	LEFT JOIN public_bodies
	ON info_requests.public_body_id = public_bodies.id;"
	# for the body on the outgoing message : select body from outgoing_messages where info_request_id=id;
	info_requests = conn.exec(sql_query).to_a

	return {
		"pedidos"  => info_requests,
		"base_url" => "http://www.quesabes.org/request/"
	}
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
	key = data.keys.first
	CSV.open(output_path, "wb") do |csv|
		csv << data[key].first.keys
		data[key].each do |org|
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
