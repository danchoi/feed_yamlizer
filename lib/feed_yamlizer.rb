# Takes raw feed XML as input and generates a file with YAML and raw feed item
# bodies in a uniform "UTF-8". 

# requires Ruby 1.9

require 'rexml/streamlistener'
require 'rexml/document'
require 'feed_yamlizer/feed_listener'
require 'feed_yamlizer/feed_parser'
require 'fileutils'
require 'yaml'

class FeedYamlizer 
  include FileUtils::Verbose

  # Takes feed result as hash. Generate this with FeedParser
  def initialize(feed)
    @feed = feed
    @result = {:items => []}
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
    content = item[:content] || item[:summary] || "" 
    @result[:items][-1][:content] = content.strip + "\n"
  end

  def self.run
    feed_xml = STDIN.read
    parsed_data = FeedYamlizer::FeedParser.new(feed_xml).result
    result = FeedYamlizer::FeedYamlizer.new(parsed_data).result
    STDOUT.puts result.to_yaml
  end

end


