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

require 'csv'

def String.titleize
  self.tr('ÁÉÍÓÚ', 'áéíóú').split(' ').map(&:capitalize).join(' ')
end

updated_bodies = {}
new_bodies = {}
csv = CSV.foreach('../quesabes-data/uaip_import/responsables-a-julio-2015.csv', :encoding => 'ISO-8859-3', :headers => true, :col_sep => ';') do |row|
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
    updated_bodies[body] = email if existent_body.try(:request_email) != email
  else
    new_bodies[body.titleize] = email
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
#  * duplicate entries
#  * download latest csv file from the api: https://catalogodatos.gub.uy/api/3/action/package_show?id=datos-de-responsables-de-transparencia
#  * add a file to this directory to keep track of the last imported version
#  * Setup the new hierarchy
