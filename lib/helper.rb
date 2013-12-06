require 'json'
require 'csv'

def connect_to_db
	return PG.connect( dbname: 'foi_production' )
end

## estadisticas
#                  organismo, cantidad_pedidos, estado  <--- donde
#tenemos cantidad de pedidos por clasificacion (rechazado, esperando,
#aceptado)
def get_requests_per_public_body(conn)

    sql_query = "SELECT public_bodies.name as organismo, count(info_requests.described_state) as cantidad_pedidos, info_requests.described_state as estado
    FROM info_requests 
    RIGHT JOIN public_bodies
	ON public_bodies.id = info_requests.public_body_id
	GROUP BY public_bodies.name, info_requests.described_state;"

	info_requests_per_public_body = conn.exec(sql_query).to_a
 
 	return {
 		"cantidad_pedidos_per_organismo" => info_requests_per_public_body
 	}
end


## pedidos
#    titulo, descripcion, fecha de realizado, organismo, estado, url
# info_requests
#    title, ..., created_at, public_body_id, described_state, url_title
# url will be http://quesabes.org/request/"url_title"
def get_info_requests(conn)
	sql_query = "SELECT info_requests.title as pedido, info_requests.created_at as fecha_de_realizado, 
	info_requests.described_state as estado, info_requests.url_title as titulo_url, public_bodies.name as organismo
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
	public_bodies = conn.exec( "SELECT name as nombre, short_name as nombre_corto, request_email as correo, home_page as web FROM public_bodies" ).to_a
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
