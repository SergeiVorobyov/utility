class Cue
  def initialize(filepath)
    @data = {tracks: {}}

    current_track_number = nil

    File.readlines(filepath).each do |line|
      current_track_number = line.scan(/TRACK (\d+) AUDIO/).first.first if line =~ /TRACK/

      if current_track_number

        idx = current_track_number.to_i
        data[:tracks][idx] ||= {track_num_str: current_track_number}

        if line =~ /TITLE/
          title = line.scan(/TITLE "(.+)"/).first.first
          data[:tracks][idx][:title] = title
          data[:tracks][idx][:filename] = self.clean_filename("#{current_track_number}. #{title}.flac")
        end

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

      if current_track_number
        idx = current_track_number.to_i
        data[:tracks][idx] ||= {track_num_str: current_track_number}
        if line =~ /TITLE/
          
          data[:tracks][idx][:title] = title
          
        end
        
        if line =~ /INDEX/
          start = line.scan(/INDEX \d+ (.+)/).first.first.split(':')
          data[:tracks][idx][:start] = start
          data[:tracks][idx - 1][:end] = start if data[:tracks].size > 1
        end
      else
        [:performer, :title, :date, :file].each do |tag|
          data[tag] = line.scan(/#{tag.to_s.upcase} "(.+)"/).first.first if line =~ /#{tag.to_s.upcase}/
        end
      end
    end
  end

  def data
    @data
  end

  def tracks
    @data[:tracks]
  end

  def debug
    require 'json'
    puts JSON.pretty_generate(data)
  end

  def to_file(filename)
    File.open(filename, 'w+') do |f|
      f.puts "PERFORMER \"#{data[:performer]}\""
      f.puts "TITLE \"#{data[:title]}\""
      f.puts "REM DATE \"#{data[:date]}\""

      tracks.each do |track_num, track|
        f.puts "FILE \"#{track[:filename]}\" FLAC"
        f.puts "  TRACK #{track[:track_num_str]} AUDIO"
        f.puts "    TITLE \"#{track[:title]}\""
        f.puts "    PERFORMER \"#{data[:performer]}\""
        f.puts "    INDEX 01 00:00:00"
      end
    end
  end

protected

  def clean_filename(source)
    source.gsub("\\", '').gsub("/", '').gsub("*", '#').gsub("?", '').gsub('"', "'").gsub(':', "-").gsub("\t", '').gsub("|", '-').gsub("\r", '').gsub('>', '').gsub('<', '')
  end
end