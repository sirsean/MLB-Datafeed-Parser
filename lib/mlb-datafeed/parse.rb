module MLB
    module Datafeed
        class Parser
            def initialize(team, start_date, players)
                @local_reader = LocalFileReader.new
                @team = team
                @start_date = start_date
                @players = players
            end

            def parse
                batters = {}

                @local_reader.known_game_ids.select{|game_id| /.*_#{@team}mlb_.*/.match(game_id)}.each do |game_id|
                    date = @local_reader.date_by_game_id(game_id)
                    if date >= @start_date
                        doc = REXML::Document.new(@local_reader.file_contents(game_id))
                        doc.elements.collect("boxscore/batting[@team_flag='#{team_flag(doc)}']/batter"){ |elem|
                            Model::BatterGameScore.new(date, elem) if (@players.nil? or @players.include?(elem.attributes["name_display_first_last"]))
                        }.select{|game_score| not game_score.nil?}.each{ |game_score|
                            if not batters.has_key?(game_score.name)
                                batters[game_score.name] = Model::Batter.new(game_score.name)
                            end
                            batters[game_score.name] << game_score
                        }
                    end
                end

                return batters
            end

            def team_flag(doc)
                flag = "home"
                doc.elements.each("boxscore") do |elem|
                    home_team_code = elem.attributes['home_team_code']
                    away_team_code = elem.attributes['away_team_code']
                    if home_team_code == @team
                        flag = "home"
                    elsif away_team_code == @team
                        flag = "away"
                    end
                end
                return flag
            end
        end
    end
end
