require "rexml/document"
require "net/http"

class Fixnum
    def num_digits
        abs.floor.to_s.split('').size
    end

    def with_prefix(digits, character)
        fill = ''
        (digits - num_digits).times{|x| fill += character.to_s }
        fill + self.to_s
    end
end

module MLB
    module Datafeed
        class Downloader
            def initialize(date)
                @local_reader = LocalFileReader.new
                @date = date
                @game_ids = []
            end

            def game_ids
                if not @game_ids.empty?
                    return @game_ids
                else
                    Net::HTTP.start("gd2.mlb.com"){ |http|
                        resp = http.get(remote_base_path)
                        doc = REXML::Document.new(resp.body)
                        doc.elements.each("html/body/ul/li/a"){ |elem|
                            if elem.attributes["href"] =~ /gid_.*/
                                @game_ids << elem.attributes["href"].gsub("/", "")
                            end
                        }
                    }
                    return @game_ids
                end
            end
            
            def remote_base_path
                "/components/game/mlb/year_#{@date.year}/month_#{@date.month.with_prefix(2,0)}/day_#{@date.day.with_prefix(2,0)}/"
            end

            def remote_filename(game_id)
                remote_base_path + game_id + "/boxscore.xml"
            end

            def file_contents(game_id)
                if @local_reader.game_known?(game_id)
                    puts "Already downloaded: #{game_id}"
                    return @local_reader.file_contents(game_id)
                else
                    puts "Downloading: #{game_id}"
                    Net::HTTP.start("gd2.mlb.com") do |http|
                        resp = http.get(remote_filename(game_id))
                        if resp.code.to_s == 200.to_s
                            File.open(@local_reader.local_filename(game_id), "wb") do |file|
                                file.write(resp.body)
                            end
                            return resp.body
                        else
                            return nil
                        end
                    end
                end
            end
        end
    end
end
