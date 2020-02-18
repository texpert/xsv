module Xsv
  class Sheet
    attr_reader :xml

    def initialize(workbook, xml)
      @workbook = workbook
      @xml = xml
      @headers = []
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id}>"
    end

    # Iterate over rows. Returns an array if read_headers is false, or a hash
    # with first row values as keys if read_headers is true
    def each_row(read_headers: false)
      @parse_headers if read_headers

      @xml.css("sheetData row").each do |row_xml|
        yield(parse_row(row_xml))
      end

      true
    end

    # Get row by number, starting at 0
    def [](number)
      parse_row(@xml.css("sheetData row:nth-child(#{number + 1})").first)
    end

    # Load headers in the top row of the worksheet. After parsing of headers
    # all methods return hashes instead of arrays
    def parse_headers!
      parse_headers

      true
    end

    private

    def parse_headers
      @headers = parse_row(@xml.css("sheetData row").first)
    end

    def parse_row(xml)
      if @headers.any?
        row = {}
      else
        row = []
      end

      xml.css("c").each_with_index do |c_xml, i|
        next if @headers.any? && i == 0

        value = case c_xml["t"]
          when "s"
            @workbook.shared_strings[c_xml.css("v").inner_text.to_i]
          when "str"
            c_xml.css("v").inner_text
          when "e" # N/A
            nil
          when nil
            c_xml.css("v").inner_text.to_i
          else
            raise Xsv::Error, "Encountered unknown column type #{c_xml["t"]}"
          end

        if @headers.any?
          row[@headers[i]] = value
        else
          row << value
        end
      end

      row
    end
  end
end
