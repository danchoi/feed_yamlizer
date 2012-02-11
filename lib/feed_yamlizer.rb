# Takes raw feed XML as input and generates a file with YAML and raw feed item
# bodies in a uniform "UTF-8". 

# requires Ruby 1.9

require 'rexml/streamlistener'
require 'rexml/document'
require 'feed_yamlizer/feed_listener'
require 'feed_yamlizer/feed_parser'
require 'feed_yamlizer/html_listener'
require 'feed_yamlizer/html_cleaner'
require 'nokogiri'
require 'fileutils'
require 'yaml'
require 'htmlentities'
require 'string_ext'

if ENV['FEED2YAML_ENV'] == 'debug'
  $debug = true
end

class FeedYamlizer 
  include FileUtils::Verbose

  def self.format(x, indent=0)
    res = IO.popen("fmt -w #{75 - indent}", "r+") do |pipe| 
      pipe.puts x
      pipe.close_write
      pipe.read
    end
    if indent
      res.gsub(/^(?=\S)/, ' ' * indent)
    else 
      res
    end
  end

  def initialize(feed)
    @feed = feed
    @result = {:meta => {}, :items => []}
  end

  def result
    add_feed_metaresult
    add_items
    @result
  end

  def inner_text(string)
    Nokogiri::HTML.parse(string).inner_text
  end

  def add_feed_metaresult
    @result[:meta] = {
      :title => inner_text(@feed[:title]),
      :link => @feed[:link],
      :xml_encoding => @feed[:xml_encoding]
    }
  end

  def add_items
    @feed[:items].each_with_index {|item, i| 
      add_item_metaresult item, i
      add_raw_content item, i
    }
  end

  def add_item_metaresult(item, index)
    fields = [:title, :author, :guid, :pub_date, :link, :enclosure, :podcast_image]
    x = {:title => inner_text(item[:title])}
    metaresult = fields.reduce(x) {|memo, field| 
      memo[field] = item[field]
      memo
    }
    @result[:items] << metaresult
  end

  def add_raw_content(item, index)
    content = (item[:content] || item[:summary] || "").gsub(/^\s*/, '').strip
    @result[:items][-1][:content] = {:html => content}
    # TODO check if HTML or plain text!
    simplified = HtmlCleaner.new(content).output
    #@result[:items][-1][:content][:simplified] = simplified
    textified = simplified.gsub(FeedYamlizer::NEWLINE_PLACEHOLDER, "\n").
        gsub(SPACE_PLACEHOLDER, " ").
        gsub(TAB_PLACEHOLDER, "  ").
        gsub(/^\s+$/, "").
        # eliminate extra blank lines 
        #gsub(/\n{3,}(?!\s)/, "awdkljalwkdjalwkjd lawkdj GOLD klajw d\n\n")
        #gsub(/\n{3,}(?!\s)/m, "\n\n").
        gsub(/\n *\n *\n *$/ , "\n\n")
    # next two lines are dev lines
    #puts textified
    #exit
    @result[:items][-1][:content][:text] = textified
  end

  class << self
    def xml_encoding(rawxml)
      encoding = rawxml.encode("ascii", invalid: :replace, undef: :replace)[/encoding=["']([^"']+)["']/,1]
      if $debug
        STDERR.puts "xml encoding: #{encoding.inspect}"
      end
      encoding
    end

    def check_for_tidy
      if `which tidy` == ''
        abort "Please install tidy"
      end
    end

    # main method
    def run(feed_xml, encoding='UTF-8')
      check_for_tidy
      feed_xml = Iconv.conv("UTF-8//TRANSLIT//IGNORE", encoding, feed_xml)
      parsed_data = FeedYamlizer::FeedParser.new(feed_xml).result
      result = FeedYamlizer.new(parsed_data).result
      result
    end

    def process_xml(xml)
      run xml, xml_encoding(xml)
    end

    def process_url(url)
      response = open(url)
      charset = response.charset
      #STDERR.puts "charset: #{charset}"
      xml = response.read
      encoding = charset || xml_encoding(xml) || "UTF-8"
      run xml, encoding
    end
  end
end


