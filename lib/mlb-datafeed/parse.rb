module MLB
    module Datafeed
        class Parser
            def initialize(options)
                @local_reader = LocalFileReader.new
                @team = options[:team]
                @start_date = options[:start_date]
                @players = options[:players]
            end

            def parse
                if not @team.nil?
                    return parse_team(@team)
                elsif not @players.nil?
                    return parse_players(@players)
                else
                    raise "Unknown parse method"
                end
            end

            private

            def parse_team(team)
                batters = MLB::Datafeed::Model::BattersCollection.new

                @local_reader.known_game_ids.select{|game_id| game_id.has_team(team)}.each do |game_id|
                    date = game_id.date
                    if date >= @start_date
                        doc = REXML::Document.new(@local_reader.file_contents(game_id))
                        doc.elements.collect("boxscore/batting[@team_flag='#{team_flag(doc, team)}']/batter"){ |elem|
                            Model::BatterGameScore.new(date, elem)
                        }.select{|game_score| not game_score.nil?}.each{ |game_score|
                            if not batters.has_batter?(game_score.name)
                                batters[game_score.name] = Model::Batter.new(game_score.name)
                            end
                            batters[game_score.name] << game_score
                        }
                    end
                end

                return batters
            end

            def parse_players(players)
                batters = MLB::Datafeed::Model::BattersCollection.new

                @local_reader.known_game_ids.each do |game_id|
                    date = game_id.date
                    if date >= @start_date
                        doc = REXML::Document.new(@local_reader.file_contents(game_id))
                        doc.elements.collect("boxscore/batting/batter"){ |elem|
                            Model::BatterGameScore.new(date, elem) if players.include?(elem.attributes["name_display_first_last"])
                        }.select{|game_score| not game_score.nil?}.each{ |game_score|
                            if not batters.has_batter?(game_score.name)
                                batters[game_score.name] = Model::Batter.new(game_score.name)
                            end
                            batters[game_score.name] << game_score
                        }
                    end
                end

                return batters
            end

            def team_flag(doc, team)
                flag = "home"
                doc.elements.each("boxscore") do |elem|
                    home_team_code = elem.attributes['home_team_code']
                    away_team_code = elem.attributes['away_team_code']
                    if home_team_code == team
                        flag = "home"
                    elsif away_team_code == team
                        flag = "away"
                    end
                end
                return flag
            end
        end
    end
end
