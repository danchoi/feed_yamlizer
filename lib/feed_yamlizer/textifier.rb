# just takes simplified HTML and converts it to plain text
class FeedYamlizer
  class Textifier
    def initialize(html)
      @doc = Nokogiri::HTML.parse(html)
    end

    def output
      @doc.inner_text
    end

  end
end


