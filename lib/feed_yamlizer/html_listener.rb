class FeedYamlizer
  NEWLINE_PLACEHOLDER = '+---NEWLINE---+'
  SPACE_PLACEHOLDER = '+---SPACE---+'
  TAB_PLACEHOLDER = '+---TAB---+'

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

      x = Nokogiri::HTML.parse(x).inner_text
      # wrap the text
      x = FeedYamlizer.format(x)

      # format the blockquotes
      line_buffer = []
      blockquote_buffer = []
      inblock = false
      x.split(/\n/).each do |line|
        if line == '[blockquote]'
          inblock = true
        elsif line == '[/blockquote]'
          inblock = false
          block = blockquote_buffer.join("\n")
          line_buffer << (FeedYamlizer.format(block, 4))
          blockquote_buffer = []
        else
          if inblock 
            blockquote_buffer << " " * 4 + line.to_s
          else
            line_buffer << line
          end
        end
      end
      x = line_buffer.join("\n")
      

      res = x + "\n\n" + @links.map {|x| 
        gutter = x[:index].to_s.rjust(digits)
        if x[:content] && x[:content].strip.length > 0
          %Q|#{gutter}. "#{x[:content].gsub(/[\r\n]+/, ' ').strip}"\n#{' ' * (digits + 2)}#{x[:href]}|
        else
          "#{gutter}. #{x[:href]}"
        end
      }.join("\n")
      res 
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
        chunk = "[img:#{text}] "
        @content[-1] << chunk
      when *HEADER_TAGS
        @content << "<#{UNIFORM_HEADER_TAG}>" 
      when 'br' #skip
        #@content << "<br/>"
        # @content << ""
        @content[-1] += " " 
      when 'blockquote'
        @content += ["[blockquote]", ""]
      when 'ul', 'ol', 'dl'
        @content << "<#{name}>\n"
      when 'li', 'dt', 'dd'
        @content += ["[blockquote]", "", "* "]
      when 'strong', 'em'
        @content[-1] << "<#{name}>"
      when *BLOCK_TAGS
        @content << "<p>"
      when 'pre'
        @pre = true
        @content << "[pre]\n"
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
        @content += ["","[/blockquote]", '']
      when 'ul', 'ol', 'dl'
        @content[-1] << "</#{name}>"
      when 'li', 'dt', 'dd'
        @content += ["", "[/blockquote]", '']
      when 'strong', 'em'
        @content[-1] << "</#{name}>"
      when *BLOCK_TAGS
        @content[-1] << "</p>"
      when 'pre'
        @pre = false
        @content[-1] << "\n[/pre]"
      end
    end

    def text(text)
      return if text =~ /\a\s*\Z/
      if @in_link 
        (@links[-1][:content] ||= "") << text
        return
      end

      if @pre 
        @content[-1] << text.gsub("\n", NEWLINE_PLACEHOLDER).gsub(/\t/, TAB_PLACEHOLDER).gsub(" ", SPACE_PLACEHOLDER)
      else
        @content[-1] << text
      end
    end

    def start_of_block?
      BLOCK_TAGS.include? @nested_tags[-1] 
    end

    def path
      @nested_tags.join('/')
    end


  end
end
