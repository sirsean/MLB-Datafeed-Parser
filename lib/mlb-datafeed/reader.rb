module MLB
    module Datafeed
        class LocalFileReader
            def known_game_ids
                regex = /xml\/(.+)\.xml/
                Dir.glob("xml/*.xml").map do |filename|
                    MLB::Datafeed::Model::GameId.new(regex.match(filename)[1])
                end
            end

            def local_filename(game_id)
                "xml/" + game_id.gid + ".xml"
            end

            def file_contents(game_id)
                File.read(local_filename(game_id))
            end

            def game_known?(game_id)
                File.exists?(local_filename(game_id))
            end

            def latest_downloaded_date
                known_game_ids.map{|game_id| game_id.date}.sort.last
            end
        end
    end
end
