require 'optparse'

module Twine
  class CLI
    def initialize(args, options)
      @options = options
      @args = args
    end

    def self.parse_args(args, options)
      new(args, options).parse_args
    end

    def parse_args
      parser = OptionParser.new(@args) do |opts|
        opts.banner = 'Usage: twine COMMAND STRINGS_FILE [INPUT_OR_OUTPUT_PATH] [--lang LANG1,LANG2...] [--tag TAG1,TAG2,TAG3...] [--format FORMAT]'
        opts.separator ''
        opts.separator 'The purpose of this script is to convert back and forth between multiple data formats, allowing us to treat our strings (and translations) as data stored in a text file. We can then use the data file to create drops for the localization team, consume similar drops returned by the localization team, generate reports on the strings, as well as create iOS and Android string files to ship with our products.'
        opts.separator ''
        opts.separator 'Commands:'
        opts.separator ''
        opts.separator 'generate-strings-file -- Generates a string file in a certain LANGUAGE given a particular FORMAT. This script will attempt to guess both the language and the format given the filename and extension. For example, "ko.xml" will generate a Korean language file for Android.'
        opts.separator ''
        opts.separator 'generate-all-string-files -- Generates all the string files necessary for a given project. The parent directory to all of the locale-specific directories in your project should be specified as the INPUT_OR_OUTPUT_PATH. This command will most often be executed by your build script so that each build always contains the most recent strings.'
        opts.separator ''
        opts.separator 'consume-string-file -- Slurps all of the strings from a translated strings file into the specified STRINGS_FILE. If you have some files returned to you by your translators you can use this command to incorporate all of their changes. This script will attempt to guess both the language and the format given the filename and extension. For example, "ja.strings" will assume that the file is a Japanese iOS strings file.'
        opts.separator ''
        opts.separator 'generate-loc-drop -- Generates a zip archive of strings files in any format. The purpose of this command is to create a very simple archive that can be handed off to a translation team. The translation team can unzip the archive, translate all of the strings in the archived files, zip everything back up, and then hand that final archive back to be consumed by the consume-loc-drop command.'
        opts.separator ''
        opts.separator 'consume-loc-drop -- Consumes an archive of translated files. This archive should be in the same format as the one created by the generate-loc-drop command.'
        opts.separator ''
        opts.separator 'generate-report -- Generates a report containing data about your strings. For example, it will tell you if you have any duplicate strings or if any of your strings are missing tags. In addition, it will tell you how many strings you have and how many of those strings have been translated into each language.'
        opts.separator ''
        opts.separator 'General Options:'
        opts.separator ''
        opts.on('-l', '--lang LANGUAGES', Array, 'The language code(s) to use for the specified action.') do |langs|
          @options[:languages] = langs
        end
        opts.on('-t', '--tag TAGS', Array, 'The tag(s) to use for the specified action. Only strings with that tag will be processed.') do |tags|
          @options[:tags] = tags
        end
        opts.on('-f', '--format FORMAT', 'The file format to read or write (iOS, Android). Additional formatters can be placed in the formats/ directory.') do |format|
          lformat = format.downcase
          found_format = false
          Formatters::FORMATTERS.each do |formatter|
            if formatter::FORMAT_NAME == lformat
              found_format = true
              break
            end
          end
          if !found_format
            puts "Invalid format: #{format}"
          end
          @options[:format] = lformat
        end
        opts.on('-h', '--help', 'Show this message.') do |h|
          puts opts.help
          exit
        end
        opts.on('--version', 'Print the version number and exit.') do |x|
          puts "Twine version #{Twine::VERSION}"
          exit
        end
        opts.separator ''
        opts.separator 'Examples:'
        opts.separator ''
        opts.separator '> twine generate-string-file strings.txt ko.xml --tag FT'
        opts.separator '> twine generate-all-string-files strings.txt Resources/Locales/ --tag FT,FB'
        opts.separator '> twine consume-string-file strings.txt ja.strings'
        opts.separator '> twine generate-loc-drop strings.txt LocDrop5.zip --tag FT,FB --format android --lang de,en,en-GB,ja,ko'
        opts.separator '> twine consume-loc-drop strings.txt LocDrop5.zip'
        opts.separator '> twine generate-report strings.txt'
      end
      parser.parse!

      if @args.length == 0
        puts parser.help
        exit
      end

      @options[:command] = @args[0]

      if !VALID_COMMANDS.include? @options[:command]
        puts "Invalid command: #{@options[:command]}"
        exit
      end

      if @args.length == 1
        puts 'You must specify your strings file.'
        exit
      end

      @options[:strings_file] = @args[1]

      case @options[:command]
      when 'generate-string-file'
        if @args.length == 3
          @options[:output_path] = @args[2]
        elsif @args.length > 3
          puts "Unknown argument: #{@args[3]}"
          exit
        else
          puts 'Not enough arguments.'
          exit
        end
        if @options[:languages] and @options[:languages].length > 1
          puts 'Please only specify a single language for the generate-string-file command.'
          exit
        end
      when 'generate-all-string-files'
        if ARGV.length == 3
          @options[:output_path] = @args[2]
        elsif @args.length > 3
          puts "Unknown argument: #{@args[3]}"
          exit
        else
          puts 'Not enough arguments.'
          exit
        end
      when 'consume-string-file'
        if @args.length == 3
          @options[:input_path] = @args[2]
        elsif @args.length > 3
          puts "Unknown argument: #{@args[3]}"
          exit
        else
          puts 'Not enough arguments.'
          exit
        end
        if @options[:languages] and @options[:languages].length > 1
          puts 'Please only specify a single language for the consume-string-file command.'
          exit
        end
      when 'generate-loc-drop'
        if @args.length == 3
          @options[:output_path] = @args[2]
        elsif @args.length > 3
          puts "Unknown argument: #{@args[3]}"
          exit
        else
          puts 'Not enough arguments.'
          exit
        end
        if !@options[:format]
          puts 'You must specify a format.'
          exit
        end
      when 'consume-loc-drop'
        if @args.length == 3
          @options[:input_path] = @args[2]
        elsif @args.length > 3
          puts "Unknown argument: #{@args[3]}"
          exit
        else
          puts 'Not enough arguments.'
          exit
        end
      when 'generate-report'
        if @args.length > 2
          puts "Unknown argument: #{@args[2]}"
          exit
        end
      end
    end
  end
end
