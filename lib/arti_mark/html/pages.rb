require 'securerandom'
module ArtiMark
  module Html
    class Context
      class Pages
        attr_reader :created_files
        def initialize(filename_prefix = nil, sequence_format='%05d')
          @filename_prefix = filename_prefix || "noramark_#{SecureRandom.uuid}"
          @sequence_format = sequence_format || '%05d'
          @result = []
        end

        def last
          @result.last[:content]
        end

        def size
          @result.size
        end
        
        def <<(page)
          seq = @result.size + 1
          @result << { content: page, filename: "#{@filename_prefix}_#{@sequence_format%(seq)}.xhtml" }
        end

        def [](num)
          page = @result[num]
          page.nil? ? nil : page[:content]
        end
        
        def write_as_files(directory: nil)
          dir = directory || Dir.pwd
          Dir.chdir(dir) do
            @result.each do
              |page|
              File.open(page[:filename], 'w+') do
                |file|
                file << page[:content]
              end
            end
          end
        end 
        def write_as_single_file(filename)
          File.open(filename, 'w+') {
            |file|
            file << @result[0][:content]
          }
        end
      end
    end
  end
end
