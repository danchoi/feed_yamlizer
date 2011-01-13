# Takes raw feed XML as input and generates a file with YAML and raw feed item
# bodies in a uniform "UTF-8". 

# requires Ruby 1.9

require 'rexml/streamlistener'
require 'rexml/document'
require 'feed_yamlizer/feed_listener'
require 'feed_yamlizer/feed_parser'
require 'feed_yamlizer/html_listener'
require 'feed_yamlizer/html_stripper'
require 'nokogiri'
require 'feed_yamlizer/textifier'
require 'fileutils'
require 'yaml'

class FeedYamlizer 
  include FileUtils::Verbose

  # Takes feed result as hash. Generate this with FeedParser
  def initialize(feed)
    @feed = feed
    @result = {:meta => {}, :items => []}
  end

  def result
    add_feed_metaresult
    add_items
    #encode(result)
    # REXML encodes everything to UTF-8
    @result
  end

  # encoding method
  def encode(string)
    return unless string
    return string unless @orig_encoding
    if @orig_encoding && @orig_encoding.upcase == "UTF-8"
      return string 
    end
    string.force_encoding(@orig_encoding)
    string.encode!("UTF-8", undef: :replace, invalid: :replace)
    string
  end

  def add_feed_metaresult
    fields = [:title, :link, :orig_encoding]
    @orig_encoding = @feed[:orig_encoding]
    @result[:meta] = fields.reduce({}) {|memo, field| 
      memo[field] = encode(@feed[field]); memo
    }
  end

  def add_items
    @feed[:items].each_with_index {|item, i| 
      add_item_metaresult item, i
      add_raw_content item, i
    }
  end

  def add_item_metaresult(item, index)
    fields = [:title, :author, :guid, :pub_date, :link]
    metaresult = fields.reduce({}) {|memo, field| 
      memo[field] = if field == :pub_date 
                      item[field]
                    else
                      encode(item[field])
                    end
      memo
    }
    @result[:items] << metaresult
  end

  def add_raw_content(item, index)
    content = (item[:content] || item[:summary] || "").gsub(/^\s*/, '').strip
    @result[:items][-1][:content] = {:html => content}
    # TODO check if HTML or plain text!
    simplified = HtmlStripper.new(content, @orig_encoding).output
    textified = Textifier.new(simplified).output 
    @result[:items][-1][:content][:simplified] = simplified
    @result[:items][-1][:content][:text] = textified
  end

  def self.run
    check_for_tidy
    feed_xml = STDIN.read
    parsed_data = FeedYamlizer::FeedParser.new(feed_xml).result
    result = FeedYamlizer.new(parsed_data).result
    STDOUT.puts result.to_yaml
  end

  def self.check_for_tidy
    if `which tidy` == ''
      abort "Please install tidy"
    end
  end
end


