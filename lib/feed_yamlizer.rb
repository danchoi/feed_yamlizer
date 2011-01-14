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
require 'feed_yamlizer/textifier'
require 'fileutils'
require 'yaml'
require 'htmlentities'

class FeedYamlizer 
  include FileUtils::Verbose

  def initialize(feed)
    @feed = feed
    @result = {:meta => {}, :items => []}
  end

  def result
    add_feed_metaresult
    add_items
    @result
  end

  def add_feed_metaresult
    fields = [:title, :link, :xml_encoding]
    @xml_encoding = @feed[:xml_encoding]
    @result[:meta] = fields.reduce({}) {|memo, field| 
      memo[field] = @feed[field]
      memo
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
    textified = Textifier.new(simplified).output 
    @result[:items][-1][:content][:simplified] = simplified
    @result[:items][-1][:content][:text] = textified
  end

  def self.run(feed_xml)
    check_for_tidy
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


