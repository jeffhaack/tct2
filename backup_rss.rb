# Please note that this has been heavily edited to work for the TCT website

require 'mini_magick'

module JekyllImport
  module Importers
    class RSS < Importer
      def self.specify_options(c)
        c.option 'source', '--source NAME', 'The RSS file or URL to import'
      end

      def self.validate(options)
        if options['source'].nil?
          abort "Missing mandatory option --source."
        end
      end

      def self.require_deps
        JekyllImport.require_with_fallback(%w[
          rss
          rss/1.0
          rss/2.0
          open-uri
          fileutils
          safe_yaml
        ])
      end

      # Process the import.
      #
      # source - a URL or a local file String.
      #
      # Returns nothing.
      def self.process(options)
        source = options.fetch('source')

        content = ""
        open(source) { |s| content = s.read }
        rss = ::RSS::Parser.parse(content, false)

        raise "There doesn't appear to be any RSS items at the source (#{source}) provided." unless rss

        rss.items.each do |item|
          formatted_date = item.date.strftime('%Y-%m-%d')
          post_name = item.title.split(%r{ |!|/|:|&|-|$|,}).map do |i|
            i.downcase if i != ''
          end.compact.join('-')
          name = "#{formatted_date}-#{post_name}"

          # A super ugly way to get the first image
          firstImg = item.content_encoded.partition("img src='").last.partition('jpg').first + "jpg"
          # Now resize and save
          firstImgB = MiniMagick::Image.open(firstImg)
          firstImgB.resize "500x333"
          #firstImgB.crop('500x333+0+0')
          firstImgB.format "jpg"
          firstImgB.write "assets/blog/media/#{formatted_date}-fb.jpg"
          #firstImgB.crop "480x125"
          #firstImgB.format "jpg"
          firstImgB.crop('480x125+0+0')
          firstImgB.write "assets/blog/media/#{formatted_date}-big.jpg"

          header = {
            'layout' => 'blog',
            'title' => item.title,
            'permalink' => '/en/blog/' + item.title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '') + '/',
            'lang' => 'en',
            'category' => 'blog',
            'author' => 'Tom Allen',
            'thumb-big' => "/assets/blog/media/#{formatted_date}-big.jpg",
            'thumb-fb' => "/assets/blog/media/#{formatted_date}-fb.jpg"
          }

          FileUtils.mkdir_p("_posts")

          File.open("_posts/#{name}.html", "w") do |f|
            f.puts header.to_yaml
            f.puts "---\n\n"
            f.puts item.content_encoded
            puts item.content_encoded.partition("img src='").last.partition('jpg').first + "jpg"
          end
        end
      end
    end
  end
end
