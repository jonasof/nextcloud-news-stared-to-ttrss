require 'json'
require 'builder'
require "zlib"

schema_version = '133'
nextcloud_exported_file = 'data/articles.json'
ttrss_xml_destination = 'data/ttrss.xml'
ttrss_gz_destination = 'data/ttrss.gz'

unless File.file?(nextcloud_exported_file)
    abort('File ' + nextcloud_exported_file + ' does not exists')
end

articles = JSON.parse(File.read(nextcloud_exported_file))

builder = Builder::XmlMarkup.new
xml = builder.articles(:'schema-version'=> schema_version) { |articles_new|
    articles.each { |original_article|
        articles_new.article { |article|
            article.guid() { |guid| guid.cdata! original_article['guid'] }
            article.title { |title| title.cdata! original_article['title'] }
            article.content { |content| content.cdata! original_article['body'] }
            article.marked { |marked| marked.cdata! '1' }
            article.link { |link| link.cdata! original_article['feedLink'] }

            published_time = Time.at(!original_article['pubDate'].nil? ? original_article['pubDate'] : 0).strftime "%Y-%m-%d %H:%M:%S"
            article.published { |published| published.cdata! published_time }

            updated_time = Time.at(!original_article['updatedDate'].nil? ? original_article['updatedDate'] : 0).strftime "%Y-%m-%d %H:%M:%S"
            article.updated { |updated| updated.cdata! updated_time }
        }
    }
}

final_xml = '<?xml version="1.0" encoding="UTF-8"?>' + xml

File::write(ttrss_xml_destination, final_xml)
Zlib::GzipWriter.open(ttrss_gz_destination) { |gz| gz.write final_xml }
