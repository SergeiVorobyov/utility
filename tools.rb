class Tools
  def self.remux_to_mkv(start_folder, extensions = ['mp4'], params = {})
    # Dir.glob returns no results in Windows if path contains [ ], replacing by a wildcard
    start_folder = start_folder.gsub('[', '*').gsub(']', '*')

    videos = Dir.glob("#{start_folder}/**/*").reject{|f| File.directory?(f)}.select{|f| extensions.include?(f.split('.')[-1].downcase)}
    videos.each do |old_video_path|
      extension = old_video_path.split('.')[-1]
      new_video_path = old_video_path.gsub(".#{extension}", '.mkv')

      command = "mkvmerge -o \"#{new_video_path}\" \"#{old_video_path}\""
      command = command.gsub('/','\\')
      puts "Command: #{command}"

      if !params[:test_mode]
        IO.popen(command).each do |line|
          p line.chomp
        end

        new_size = File.size(new_video_path)

        # no error code returned by mkvmerge and the new file is not empty
        if $?.to_i == 0 && new_size > 0
          File.delete(old_video_path) if !params[:keep_old]
        else
          raise 'Something went wrong!'
        end
      end

      puts '='*80
    end

    'done'
  end
end