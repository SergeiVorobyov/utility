CUE = "Modern Talking Let's Talk About Love.cue"

def clean_filename(source)
  source.gsub("\\", '').gsub("/", '').gsub("*", '#').gsub("?", '').gsub('"', "'").gsub(':', "-").gsub("\t", '').gsub("|", '-').gsub("\r", '').gsub('>', '').gsub('<', '')
end

data = {tracks: {}}
current_track_number = nil

File.readlines(CUE).each do |line|
  current_track_number = line.scan(/TRACK (\d+) AUDIO/).first.first if line =~ /TRACK/

  if current_track_number
    idx = current_track_number.to_i
    data[:tracks][idx] ||= {track_num_str: current_track_number}
    data[:tracks][idx][:title] = line.scan(/TITLE "(.+)"/).first.first if line =~ /TITLE/
    if line =~ /INDEX/
      start = line.scan(/INDEX \d+ (.+)/).first.first.gsub(/:(\d{2})$/, ',\1')
      data[:tracks][idx][:start] = start
      data[:tracks][idx - 1][:end] = start if data[:tracks].size > 1
    end
  else
    [:performer, :title, :date, :file].each do |tag|
      data[tag] = line.scan(/#{tag.to_s.upcase} "(.+)"/).first.first if line =~ /#{tag.to_s.upcase}/
    end
  end
end

# Un-comment the following two lines in order to debug the code.
#require 'json'
#puts JSON.pretty_generate(data)

data[:tracks].each do |track_num, track|
  result_filename = clean_filename("#{track[:track_num_str]}. #{track[:title]}.flac")
  `flac.exe -8 --silent --exhaustive-model-search #{"--skip=\"#{track[:start]}\" " if track[:start]} #{"--until=\"#{track[:end]}\" " if track[:end]} --tag=ARTIST="#{data[:artist]}" --tag=ALBUM="#{data[:title]}" --tag=DATE="#{data[:date]}" --tag=TITLE="#{track[:title]}" --tag=TRACKNUMBER="#{track[:track_num_str]}" "#{data[:file]}" --output-name="#{result_filename}"`
end