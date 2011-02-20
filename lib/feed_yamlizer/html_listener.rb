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
        select {|line| line.strip != ""}.
        compact.
        join("\n\n")

      digits = @links.size.to_s.size 

      x = format(x)

      x + "\n\n" + @links.map {|x| 
        gutter = x[:index].to_s.rjust(digits)
        if x[:content] && x[:content].strip.length > 0
          %Q|#{gutter}. "#{x[:content].gsub(/[\r\n]+/, ' ').strip}"\n#{' ' * (digits + 2)}#{x[:href]}|
        else
          "#{gutter}. #{x[:href]}"
        end
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
        @in_link = true
      when 'img'
        text = attrs['alt'] || attrs['title']
        chunk = ['img', text].join(':')
        @content[-1] << chunk
      when *HEADER_TAGS
        @content << "<#{UNIFORM_HEADER_TAG}>" 
      when 'br' #skip
        #@content << "<br/>"
        # @content << ""
        @content[-1] += " " 
      when 'blockquote'
        @content << "[blockquote]\n"
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
        @links[-1][:index] = @links.size
        @in_link = false
        @content[-1] << "#{(@links[-1][:content] || '').strip.gsub(/[\r\n]+/, ' ')}[#{@links.size}]"
      when *HEADER_TAGS
        @content[-1] << "</#{UNIFORM_HEADER_TAG}>" 
      when 'blockquote'
        @content << '[/blockquote]'
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
      if @in_link 
        (@links[-1][:content] ||= "") << text
        return
      end

      # probably slow, but ok for now
      @content[-1] << text
    end

    def start_of_block?
      BLOCK_TAGS.include? @nested_tags[-1] 
    end

    def path
      @nested_tags.join('/')
    end

    def format(x)
      IO.popen("fmt", "r+") do |pipe| 
        pipe.puts x
        pipe.close_write
        pipe.read
      end
    end

  end
end
