# Takes output of feed_file_generator.rb encoded in UTF-8 as input and
# strips superfluous markup from the feed item bodies.

#require 'feed_file_generator'
require 'fileutils'
require 'rexml/streamlistener'
require 'rexml/document'
require 'open3'

# NOTE requires the htmltidy program
# http://tidy.sourceforge.net/docs/Overview.html

module FeedReducer 
  class HtmlSimplifier
    include FileUtils::Verbose
    attr :result

    # Takes feed data as hash. Generate this with FeedParser
    def initialize(html, orig_encoding)
      @orig_encoding = orig_encoding
      @xml = tidy(pre_cleanup(html))
      @result = parse.gsub(/<http[^>]+>/, "")
    end

    def parse
      @listener = FeedHtmlListener.new
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

  class FeedHtmlListener
    include REXML::StreamListener

    STRIP_TAGS = %w[ body font ]
    BLOCK_TAGS = %w[ p div ]
    HEADER_TAGS =  %w[ h1 h2 h3 h4 h5 h6 ] 

    UNIFORM_HEADER_TAG = "h4"

    def initialize
      @nested_tags = []
      @content = [""]
    end

    def result
      # we call strip_empty_tags twice to catch empty tags nested in a tag like <p>
      # not full-proof but good enough for now
      x = @content.map {|line| strip_empty_tags( strip_empty_tags( line ).strip ) }.
        select {|line| line != ""}.compact.join("\n\n")
    end

    def strip_empty_tags(line)
      line.gsub(%r{<(\w+)[^>]*>\s*</\1>}, '')
    end

    def tag_start(name, attrs)
      @nested_tags.push name
      case name 
      when 'a'
        # effectively strips out all style tags
        @content[-1] << "<a href='#{attrs['href']}'>"
      when 'img'
        if attrs['alt']
          text = (attrs['alt'].strip == '') ? 'image ' : "image:#{attrs['alt']} "
          @content[-1] << text
        end
      when *HEADER_TAGS
        @content << "<#{UNIFORM_HEADER_TAG}>" 
      when 'br' #skip
        @content << "<br/>"
      when 'blockquote'
        @content << "<blockquote>"
      when 'ul', 'ol', 'dl'
        @content << "<#{name}>"
      when 'li', 'dt', 'dd'
        @content[-1] << "  <#{name}>"
      when 'strong', 'em'
        @content[-1] << "<#{name}>"
      when *BLOCK_TAGS
        @content << "<p>"
      when 'pre'
        @content << "<pre>"
      end
    end

    def tag_end(name)
      @nested_tags.pop
      case name
      when 'a'
        @content[-1] << "</a>" 
      when *HEADER_TAGS
        @content[-1] << "</#{UNIFORM_HEADER_TAG}>" 
      when 'blockquote'
        @content << '</blockquote>'
      when 'ul', 'ol', 'dl'
        @content[-1] << "</#{name}>"
      when 'li', 'dt', 'dd'
        @content[-1] << "  </#{name}>"
      when 'strong', 'em'
        @content[-1] << "</#{name}>"
      when *BLOCK_TAGS
        @content[-1] << "</p>"
      when 'pre'
        @content[-1] << "</pre>"
      end
    end

    def text(text)
      return if text =~ /\a\s*\Z/

      # probably slow, but ok for now
      @content[-1] << text
    end

    def start_of_block?
      BLOCK_TAGS.include? @nested_tags[-1] 
    end

    def path
      @nested_tags.join('/')
    end
  end
end

def word_count(string)
  string.gsub(%{</?[^>]+>}, '').split(/\s+/).size
end


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


