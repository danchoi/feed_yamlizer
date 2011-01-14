class FeedYamlizer
  class FeedListener
    include REXML::StreamListener

    FEED_TITLE_TAGS = %w[ feed/title rss/channel/title rdf:RDF/channel/title ]
    
    FEED_LINK_TAGS = %w[ rss/channel/link rdf:RDF/channel/link ]
    
    ITEM_START_TAGS = %w[ feed/entry rss/channel/item rdf:RDF/item ] 
    
    ITEM_TITLE_TAGS = %w[ feed/entry/title rss/channel/item/title rdf:RDF/item/title ]
    
    ITEM_AUTHOR_TAGS = %w[ feed/entry/author/name rss/channel/item/author rdf:RDF/item/dc:creator ]
    
    ITEM_GUID_TAGS = %w[ feed/entry/id rss/channel/item/guid rdf:RDF/item/guid ]
    
    ITEM_PUB_DATE_TAGS = %w[ feed/entry/published feed/entry/created feed/entry/modified rss/channel/item/pubDate rdf:RDF/item/dc:date ]
    
    ITEM_LINK_TAGS = %w[ rss/channel/item/link rdf:RDF/item/link ] 
    
    ITEM_SUMMARY_TAGS = %w[ feed/entry/summary rss/channel/item/description rdf:RDF/item/description ] 
    ITEM_CONTENT_TAGS = [ %r{feed/entry/content}, %r{rss/channel/item/content}, %r{rss/channel/item/content:encoded},  %r{rss/item/content}, %r{rdf:RDF/item/content} ]

    def initialize
      @nested_tags = []
      @x = {:items => []}
    end

    def result; @x; end

    def tag_start(name, attrs)
      @nested_tags.push name
      case path
      when 'feed/link'
        @x[:link] = encode attrs['href']
      when *ITEM_START_TAGS
        @current_item = {}
      when 'feed/entry/link'
        @current_item[:link] = encode attrs['href']
      end
    end

    def tag_end(name)
      case path
      when *ITEM_START_TAGS
        @x[:items] << @current_item
        @current_item = nil
      end
      @nested_tags.pop
    end

    def text(text)
      case path
      when *FEED_TITLE_TAGS
        @x[:title] = encode text.strip
      when *FEED_LINK_TAGS 
        @x[:link] = encode text.strip
      when *ITEM_TITLE_TAGS 
        @current_item[:title] = encode(text.strip)
      when *ITEM_AUTHOR_TAGS 
        @current_item[:author] = encode(text.strip)
      when *ITEM_GUID_TAGS 
        @current_item[:guid] = encode(text)
      when *ITEM_PUB_DATE_TAGS
        @current_item[:pub_date] = DateTime.parse(encode(text))
      when *ITEM_LINK_TAGS 
        @current_item[:link] = encode(text)
      when *ITEM_SUMMARY_TAGS 
        if @current_item[:summary] 
          @current_item[:summary] << encode(text)
        else
          @current_item[:summary] = encode(text)
        end
      when *ITEM_CONTENT_TAGS
        if @current_item[:content] 
          @current_item[:content]  << encode(text)
        else
          @current_item[:content] = encode(text)
        end
      end
    end
    alias_method :cdata, :text

    def xmldecl(decl, encoding, extra)
      if encoding 
        @x[:xml_encoding] = encoding.downcase
      else
        @x[:xml_encoding] = "UTF-8"
      end
    end

    def path
      @nested_tags.join('/')
    end

    # encoding method
    # TODO
    def encode(string)
      string
    end
  end
end
