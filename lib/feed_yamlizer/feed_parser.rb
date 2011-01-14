# Custom feed parsing code by Daniel Choi dhchoi@gmail.com
# The goal is minimal dependencies (e.g. Feedzirra has too special dependencies).

# TODO
# come up with an encoding handling strategy

require 'iconv'
require 'yaml'

class FeedYamlizer
  class FeedParser
    def initialize(xml, encoding=nil)
      @xml = xml
      @listener = FeedListener.new
      REXML::Document.parse_stream(@xml, @listener)
    # TODO this is a hack, do it right
    rescue REXML::ParseException
      #puts "REXML::ParseException; converting xml to ascii"
      @xml = Iconv.conv("US-ASCII//TRANSLIT//IGNORE", "ISO-8859-1", @xml)
      REXML::Document.parse_stream(@xml, @listener)
    end

    def result
      @listener.result
    end
  end
end

