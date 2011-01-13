# Takes output of feed_file_generator.rb encoded in UTF-8 as input and
# strips superfluous markup from the feed item bodies.

#require 'feed_file_generator'
require 'fileutils'
require 'rexml/streamlistener'
require 'rexml/document'
require 'open3'

# NOTE requires the htmltidy program
# http://tidy.sourceforge.net/docs/Overview.html

class FeedYamlizer
  class HtmlTextifier
    include FileUtils::Verbose

    # Takes feed data as hash. Generate this with FeedParser
    def initialize(html, orig_encoding)
      @orig_encoding = orig_encoding
      @xml = tidy(pre_cleanup(html))
      @result = parse.gsub(/<http[^>]+>/, "")
    end

    def output
      @result
    end

    def parse
      @listener = HtmlListener.new
      REXML::Document.parse_stream(@xml, @listener)
      @listener.result + "\n\n"
    end

    def pre_cleanup(html)
      html.gsub!("<o:p></o:p>", "")
      html
    end

    def self.tidy(html, orig_encoding)
      # assumes input encoding of latin 1
      #output = Open3.popen3("tidy -q -n -wrap 120 -asxml -latin1") do |stdin, stdout, stderr|
      #output = IO.popen("tidy -q -n -wrap 120 -asxml -latin1", "r+") do |pipe|
      #output = IO.popen("tidy -q -wrap 120 -raw -asxml ", "r+") do |pipe| # if from latin1

      tidy = "tidy -q -wrap 120 -n -utf8 -asxml 2>/dev/null"
      output = IO.popen(tidy, "r+") do |pipe| 
        input = <<-END
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">
  <head><title></title></head><body>#{html}</body></html>
        END
        pipe.puts input
        pipe.close_write
        #$stderr.puts stderr.read
        pipe.read
      end
      output
    end

    def tidy(html)
      self.class.tidy html, @orig_encoding
    end
  end
end

def word_count(string)
  string.gsub(%{</?[^>]+>}, '').split(/\s+/).size
end

# all this is deprecated
if __FILE__ == $0
  # The input file is assumed to be in UTF-8
  feed_file = STDIN.read

  feed_file.force_encoding UTF-8
  segments = feed_file.split(/^-{20}$/)
  feed_meta = segments.shift
  orig_encoding = YAML::load(feed_meta)[:orig_encoding]

  new_segs = segments.map do |s|
    meta, body = s.split(/^\s*$/, 2)
    new_body = HtmlSimplifier.new(body, orig_encoding).result.strip + "\n\n"
    meta = meta + ":word_count: #{ word_count(new_body) }\n"
    [meta, new_body].join("\n")
  end
  result = ([feed_meta] + new_segs).join( '-' * 20  )
  STDOUT.puts result
end


