module MLB
    module Datafeed
        class LocalFileReader
            def known_game_ids
                regex = /xml\/(.+)\.xml/
                Dir.glob("xml/*.xml").map do |filename|
                    regex.match(filename)[1]
                end
            end

            def local_filename(game_id)
                "xml/" + game_id + ".xml"
            end

            def file_contents(game_id)
                File.read(local_filename(game_id))
            end

            def game_known?(game_id)
                File.exists?(local_filename(game_id))
            end

            def date_by_game_id(game_id)
                regex = /.*gid_(\d+)_(\d+)_(\d+)_.*/.match(game_id)
                Time.local(regex[1].to_i, regex[2].to_i, regex[3].to_i)
            end
        end
    end
end
