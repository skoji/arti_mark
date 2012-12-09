module ArtiMark
  class SyntaxHandler
    def determine_parser(lines)
      if lines[0] =~ /^d(\.\w+?)*\s*{\s*$/
        DivParser.instance
      elsif lines[0].size == 0
        ParagraphParser.instance
      elsif HeadParser.instance.accept?(lines)
        HeadParser.instance
      else
        nil
      end
    end
    def parse(lines, r)
      if parser = determine_parser(lines)
        parser.parse(lines, r, self)
      else
        ParagraphParser.instance.parse(lines, r, self)
      end
    end

  end
end