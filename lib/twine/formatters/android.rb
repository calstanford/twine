# encoding: utf-8

require 'cgi'
require 'rexml/document'

module Twine
  module Formatters
    class Android < Abstract
      FORMAT_NAME = 'android'
      EXTENSION = '.xml'
      DEFAULT_FILE_NAME = 'strings.xml'

      def self.can_handle_directory?(path)
        Dir.entries(path).any? { |item| /^values-.+$/.match(item) }
      end

      def default_file_name
        return DEFAULT_FILE_NAME
      end

      def determine_language_given_path(path)
        path_arr = path.split(File::SEPARATOR)
        path_arr.each do |segment|
          match = /^values-(.*)$/.match(path_arr)
          if match
            lang = match[1]
            lang.sub!('-r', '-')
            return lang
          end
        end

        return
      end

      def read_file(path, lang, strings)
        File.open(path, 'r:UTF-8') do |f|
          doc = REXML::Document.new(f)
          doc.elements.each('resources/string') do |ele|
            key = ele.attributes["name"]
            if strings.strings_map.include? key
              value = ele.text
              value.gsub!('\\\'', '\'')
              value.gsub!('%s', '%@')
              strings.strings_map[key].translations[lang] = value
            else
              puts "#{key} not found in strings data file."
            end
          end
        end
      end

      def write_file(path, lang, tags, strings)
        default_lang = strings.language_codes[0]
        File.open(path, 'w:UTF-8') do |f|
          f.puts "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<!-- Android Strings File -->\n<!-- Generated by Twine -->\n<!-- Language: #{lang} -->"
          f.write '<resources>'
          strings.sections.each do |section|
            printed_section = false
            section.rows.each do |row|
              if row_matches_tags?(row, tags)
                unless printed_section
                  f.puts ''
                  if section.name && section.name.length > 0
                    section_name = section.name.gsub('--', '—')
                    f.puts "\t<!-- #{section_name} -->"
                  end
                  printed_section = true
                end

                key = row.key
                key = CGI.escapeHTML(key)

                value = translated_string_for_row_and_lang(row, lang, default_lang)
                value.gsub!('\'', '\\\\\'')
                value.gsub!('%@', '%s')
                value = CGI.escapeHTML(value)

                comment = row.comment
                if comment
                  comment = comment.gsub('--', '—')
                end

                if comment && comment.length > 0
                  f.puts "\t<!-- #{comment} -->\n"
                end
                f.puts "\t<string name=\"#{key}\">#{value}</string>"
              end
            end
          end

          f.puts '</resources>'
        end
      end
    end
  end
end
