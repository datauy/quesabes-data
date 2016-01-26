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
require_relative './categories.rb'

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
  puts 'The current database is up to date. If you think this is incorrect or you want to run the script again, please remove the last_run file.'
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

  if row[INCISO_COLUMN].to_s.length > 0 && !CATEGORIES.has_key?(row[INCISO_COLUMN].to_i)
    puts "[ERROR] An unrecognized category was found: INCISO=#{row[INCISO_COLUMN]}. Please review the CSV and add all the categories to the categories.rb file."
    exit
  end

  id = "#{row[INCISO_COLUMN]}-#{row[UE_COLUMN]}"
  body = SECRETARYSHIPS[id] if SECRETARYSHIPS.has_key?(id)
  category = row[INCISO_COLUMN].to_s.length > 0 ? category_title_to_tag_name(CATEGORIES[row[INCISO_COLUMN].to_i]) : nil
  email = email.split(';').first.split('/').first.strip # use only the first email (; or / can be separators)

  existent_body = PublicBody.where('lower(name) = ?', body.downcase).first
  if existent_body
    unless updated_bodies.has_key?(existent_body.name)
      if existent_body.request_email != email
        updated_bodies[existent_body.name] ||= {}
        updated_bodies[existent_body.name][:email] = email
      end
      if existent_body.tag_string != category
        updated_bodies[existent_body.name] ||= {}
        updated_bodies[existent_body.name][:category] = category
      end
    end
  else
    new_bodies[titleize_body_name(body)] = { :email => email, :category => category }
  end
end

new_categories = []
CATEGORIES.values.each do |category|
  next if PublicBodyCategory.find_by_category_tag(category_title_to_tag_name(category))
  new_categories << category
end

puts "The following #{updated_bodies.length} bodies will change:"
puts '----------'
updated_bodies.each do |name, changes|
  puts "#{name} -> " + changes.map {|field, value| "#{field} will now be '#{value}'"}.join(', ')
end
puts

puts "The following #{new_bodies.length} bodies will be created:"
puts '----------'
new_bodies.each do |name, changes|
  puts "#{name} -> " + changes.map {|field, value| "with #{field}='#{value}'"}.join(', ')
end
puts

puts "The following #{new_categories.length} categories will be created"
puts '----------'
new_categories.each {|category| puts category }
puts

puts
print 'Apply these changes? [yN]: '
$stdout.flush
unless gets.chomp.downcase == 'y'
  puts 'Finishing without making any changes.'
  exit
end

updated_bodies.each do |name, changes|
  body = PublicBody.find_by_name(name)
  body.request_email = changes[:email]
  body.tag_string = changes[:category]
  if body.save
    puts "[INFO] Changes to body '#{body.name}' were applied successfully: #{changes}"
  else
    puts "[ERROR] Failed to update body '#{body.name}': #{body.errors.full_messages}"
  end
end

new_bodies.each do |name, changes|
  body = PublicBody.new
  body.name = name
  body.request_email = changes[:email]
  body.tag_string = changes[:category]
  body.last_edit_editor = 'UAIP import script'
  body.last_edit_comment = 'Created with the UAIP import script'
  if body.save
    puts "[INFO] Created body '#{body.name}' with attributes #{changes}"
  else
    puts "[ERROR] Failed to create body '#{body.name}': #{body.errors.full_messages}"
  end
end

new_categories.each do |category_title|
  category = PublicBodyCategory.new
  category.title = category_title
  category.description = category_title
  category.category_tag = category_title_to_tag_name(category_title)
  if category.save
    puts "[INFO] Created category '#{category.title}'"
  else
    puts "[ERROR] Failed to create category '#{category.title}': #{category.errors.full_messages}"
  end
end

puts 'Saving status file...'
File.open('last_run', 'w') do |last_run_file|
  last_run_file.puts json_resource['id']
end

puts 'Finished import operation. See the results above.'
