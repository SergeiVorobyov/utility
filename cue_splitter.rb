require_relative 'cue'
require 'parallel'

path = ARGV[0]
while path.nil? || path.empty?
  puts "Please enter the path (example: //unas.lan/temp/!!/out)"
  path = gets
end

# Normalize the path in order to work with / and \ separators correctly.
path = path.gsub('\\', '/')

cue = Cue.new(path)

path_folder = path.split('/')[0..-2].join('/')
result_cue_name = path.split('/').last
result_cue_name = result_cue_name.gsub('.cue', '-new.cue') if File.exists?(result_cue_name)
cue.to_file(result_cue_name)

Parallel.each(cue.tracks, in_threads: 4) do |track_num, track|
  puts track[:filename]
  `flac.exe -8 --silent --exhaustive-model-search #{"--skip=#{track[:start]} " if track[:start]} #{"--until=#{track[:end]} " if track[:end]} --tag=GENRE=Pop --tag=ARTIST="#{cue.data[:performer]}" --tag=ALBUMARTIST="#{cue.data[:performer]}" --tag=ALBUM="#{cue.data[:title]}" --tag=DATE="#{cue.data[:date]}" --tag=TITLE="#{track[:title]}" --tag=TRACKNUMBER="#{track[:track_num_str]}" "#{path_folder}/#{cue.data[:file]}" --output-name="#{track[:filename]}"`
end