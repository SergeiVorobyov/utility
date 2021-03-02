require 'pry'
require 'parallel'

path = ARGV[0]
while path.nil? || path.empty?
    puts "Please enter the path (example: //unas.lan/temp/!!/out)"
    path = gets
end

path = path.gsub("\\", '/')

# Change these variable to adjust the script's behaviour.
extensions_to_convert = ['dtsma', 'thd+ac3', 'thd', 'dtshr', 'pcm']
stop_words = ['Atmos', 'DTS-X']
language_conversion_rules =
[
      ['Czech', 'cze'],
      ['English', 'en'],
      ['French', 'fr'],
      ['Russian', 'ru'],
      ['Italian', 'it']
]
extensions_for_lang_rename = ['sup', 'dts', 'ac3']
languages_to_delete =
[
      'Arabic',
      'Bulgarian',
      'Chinese',
      'Croatian',
      'Danish',
      'Dutch',
      'Estonian',
      'Finnish',
      'German',
      'Hebrew',
      'Hindi',
      'Hungarian',
      'Icelandic',
      'Indonesian',
#      'Italian',
      'Japanese',
      'Korean',
      'Latvian',
      'Lithuanian',
      'Modern Greek',
      'Norwegian',
      'Polish',
      'Portuguese',
      'Romanian',
      'Serbian',
      'Slovak',
      'Slovenian',
      'Spanish',
      'Swedish',
      'Thai',
      'Turkish',
      'Ukrainian',
      'Urdu'
]

# Delete useless languages, see the 'languages_to_delete' variable to define languages that should be deleted.
print "Delete useless languages... "
Dir.glob(path + '/**/*')
   .select{|file| languages_to_delete.any?{|lang| file.include?(", #{lang},")}}
   .each{|file| File.delete(file)}
puts "done."

files = Dir.glob(path + '/**/*')
files.select!{|file| extensions_to_convert.include?(file.split('.').last)}
files.reject!{|file| stop_words.any?{|sw| file.downcase.include?(sw.downcase)}}
errors = []
errors = Parallel.map(files, in_threads: 4) { |file|
    error = nil
    new_filename = "#{file.split('.')[0..-2].join('.')}"
    language_conversion_rules.each do |full_language, short_language|
        new_filename = "#{new_filename}.#{short_language}" if new_filename.include?(full_language)
    end

    log_filename = new_filename + ' - Log.txt'
    new_filename = "#{new_filename}.flac"
    command = "eac3to \"#{file}\" \"#{new_filename}\"".gsub('/', '\\')
    puts "Going to run: #{command}"
    system(command)

    if $?.exitstatus != 0
        error = command
    else
        if File.size(new_filename) > 0 && File.size(new_filename) < File.size(file)
            File.delete(file)
            File.delete(log_filename)
        elsif File.size(new_filename) < File.size(file)
            error = "New file is larger than the original: #{command}"
            File.delete(new_filename)
        else
            error = "New file is empty for some reason: #{command}"
            File.delete(new_filename)
        end
    end
    error
}.compact

# Rename files to append a language suffix to be recognized by MkvToolNix GUI
# For example, the file '00004 - 1 - Subtitle (PGS), Russian, 1156 captions.sup'
# will be renamed to '00004 - 1 - Subtitle (PGS), Russian, 1156 captions.ru.sup'
print "Rename files to append a language suffix... "
files = Dir.glob(path + '/**/*')
files.select!{|file| extensions_for_lang_rename.include?(file.split('.').last)}
files.each do |file|
  language_conversion_rules.each do |full_language, short_language|
    if file.include?(full_language)
      extension = file.split('.').last
      File.rename(file, file.gsub(extension, "#{short_language}.#{extension}"))
    end
  end
end
puts "done."

# The final message
puts "-------------------------------------------------------------------------"
puts "Finished the job #{errors.any? ? "with #{errors.size} errors, see below:" : 'without errors'}"
errors.each{|command_with_error|
    puts command_with_error
}
