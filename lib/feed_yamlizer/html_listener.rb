class FeedYamlizer
  class HtmlListener
    include REXML::StreamListener

    STRIP_TAGS = %w[ body font ]
    BLOCK_TAGS = %w[ p div ]
    HEADER_TAGS =  %w[ h1 h2 h3 h4 h5 h6 ] 

    UNIFORM_HEADER_TAG = "h4"

    def initialize
      @nested_tags = []
      @content = [""]
      @links = []
    end

    def result
      # we call strip_empty_tags twice to catch empty tags nested in a tag like <p>
      # not full-proof but good enough for now
      x = @content.map {|line| strip_empty_tags( strip_empty_tags( line ).strip ) }.
        select {|line| line != ""}.compact.join("\n\n")
      x + "\n\n" + @links.map {|x| 
        "#{x[:index]}. #{x[:href]}"
      }.join("\n")
    end

    def strip_empty_tags(line)
      line.gsub(%r{<(\w+)[^>]*>\s*</\1>}, '')
    end

    def tag_start(name, attrs)
      @nested_tags.push name
      case name 
      when 'a'
        @links << {:href => attrs['href']}
      when 'img'
        if attrs['alt']
          text = (attrs['alt'].strip == '') ? 'image ' : "image:#{attrs['alt'] || attrs["title"]} "
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
        @links[-1][:content] = @content[-1] 
        @links[-1][:index] = @links.size
        @content[-1] = "#{@content[-1].strip}[#{@links.size}]"
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
