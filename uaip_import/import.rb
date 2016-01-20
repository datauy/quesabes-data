#!/usr/bin/env ruby

BODY_NAME_COLUMN = 'PODER EJECUTIVO'
EMAIL_COLUMN = 'MAIL DE CONTACTO'
INCISO_COLUMN = 'Inciso'
UE_COLUMN = 'UE'

IGNORE = [
  'De todo el MGAP',
]

# these have different names to identify them properly in Alaveteli,
# so we have to map them manually using Inciso-UE
SECRETARYSHIPS = {
  '4-1' => 'Dirección General de Secretaría del Ministerio del Interior',
  '8-1' => 'Dirección General de Secretaría del Ministerio De Industria, Energía y Minería',
  '12-1' => 'Dirección General de Secretaría del Ministerio de Salud Pública',
  '15-1' => 'Dirección General de Secretaría del Ministerio de Desarrollo Social',
}

require 'net/http'
require 'json'
require 'csv'

puts 'Setting up the directory...'
Dir.chdir('../quesabes-data/uaip_import/')

puts 'Connecting to catalogodatos.gub.uy...'
json = JSON.parse(Net::HTTP.get(URI('https://catalogodatos.gub.uy/api/3/action/package_show?id=datos-de-responsables-de-transparencia')))
json_resource = json['result']['resources'].last

last_imported_resource = nil
begin
  last_imported_resource = File.open('last_run', 'r', &:readline).strip
rescue
end

if last_imported_resource == json_resource['id']
  puts 'The current database is up to date.'
  exit
end

puts "Downloading '#{json_resource['name']}'..."
csv_content = Net::HTTP.get(URI(json_resource['url']))

def titleize_body_name(s)
  s.tr('ÁÉÍÓÚ', 'áéíóú').split(' ').map(&:capitalize).join(' ')
end

puts 'Processing file...'
updated_bodies = {}
new_bodies = {}
csv_content.force_encoding('ISO-8859-3')
csv = CSV.parse(csv_content, :headers => true, :col_sep => ';') do |row|
  full_body_name = row[BODY_NAME_COLUMN].to_s.strip.encode('UTF-8')
  email = row[EMAIL_COLUMN].to_s.strip.encode('UTF-8')
  full_body_name =~ /(.*:)?([^\(]*)(\s*\(.*\))?/i
  body = $2.strip
  next if body.length == 0 || email.length == 0
  next if IGNORE.include?(body)

  id = "#{row[INCISO_COLUMN]}-#{row[UE_COLUMN]}"
  body = SECRETARYSHIPS[id] if SECRETARYSHIPS.has_key?(id)
  email = email.split(';').first.split('/').first.strip # use only the first email (; or / can be separators)

  existent_body = PublicBody.where('lower(name) = ?', body.downcase).first
  if existent_body
    if existent_body.try(:request_email) != email && !updated_bodies.has_key?(existent_body.name)
      updated_bodies[existent_body.name] = email
    end
  else
    new_bodies[titleize_body_name(body)] = email
  end
end

puts "The email address of the following #{updated_bodies.length} bodies will change:"
puts '----------'
updated_bodies.each {|name, email| puts "#{name} -> #{email}"}
puts

puts "The following #{new_bodies.length} bodies will be created:"
puts '----------'
new_bodies.each {|name, email| puts "#{name} -> #{email}"}
puts

# TODO:
#  * Setup the new hierarchy -> another script?
#  * -f argument to actually run the migration

# TODO: only do this when the import operation is actually performed:
puts 'Saving status file...'
File.open('last_run', 'w') do |last_run_file|
  last_run_file.puts json_resource['id']
end

puts 'Import operation completed successfully.'
