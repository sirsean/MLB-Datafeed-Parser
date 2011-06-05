class Array
    def sum
        total = 0
        each{ |i| total += i unless i.nil? }
        total
    end

    def average
        sum / count
    end
end

module MLB
    module Datafeed
        module Model
            class GameId
                attr_reader :gid

                def initialize(gid)
                    @gid = gid
                end

                def date
                    regex = /.*gid_(\d+)_(\d+)_(\d+)_.*/.match(@gid)
                    Time.local(regex[1].to_i, regex[2].to_i, regex[3].to_i)
                end

                def has_team(team)
                    not /.*_#{team}mlb_.*/.match(@gid).nil?
                end
            end

            class BatterGameScore
                attr_reader :name, :date
                def initialize(date, elem)
                    @date = date
                    @name = elem.attributes['name_display_first_last']
                    @pos = elem.attributes['pos']
                    @ab = elem.attributes['ab'].to_i
                    @r = elem.attributes['r'].to_i
                    @bb = elem.attributes['bb'].to_i
                    @sf = elem.attributes['sf'].to_i
                    @h = elem.attributes['h'].to_i
                    @e = elem.attributes['e'].to_i
                    @d = elem.attributes['d'].to_i
                    @t = elem.attributes['t'].to_i
                    @hbp = elem.attributes['hbp'].to_i
                    @so = elem.attributes['so'].to_i
                    @hr = elem.attributes['hr'].to_i
                    @rbi = elem.attributes['rbi'].to_i
                    @sb = elem.attributes['sb'].to_i
                    @avg = elem.attributes['avg']

                    @s = (@h - @hr - @t - @d)
                    @tb = @s + 2*@d + 3*@t + 4*@hr
                end

                # (0.72xNIBB + 0.75xHBP + 0.90x1B + 0.92xRBOE + 1.24x2B + 1.56x3B + 1.95xHR) / PA
                def woba
                    val = (((0.72 * @bb) + (0.75 * @hbp) + (0.90 * @s) + (1.24 * @d) + (1.56 * @t) + (1.95 * @hr)) / (@ab + @bb + @hbp))
                    if val.nan?
                        return nil
                    else
                        return val
                    end
                end

                # ((H+BB)xTB) / (AB+BB)
                def rc
                    if @ab + @bb == 0
                        return nil
                    end
                    val = 1.0 * ( (@h + @bb) * @tb ) / (@ab + @bb)
                    return val
                end
            end

            class Batter
                attr_reader :name
                def initialize(name)
                    @name = name
                    @game_scores = []
                    @game_scores_by_date = {}
                end

                def <<(game_score)
                    @game_scores.push(game_score)
                    @game_scores_by_date[game_score.date] = game_score
                end

                def dates
                    @game_scores_by_date.keys.sort
                end

                # get the <days> moving average as of <date>
                # so if date=2010-05-28 and days=5, you'd get the 5-day moving average as of May 28, or the average of the player's performance on [2010-05-24, 2010-05-25, 2010-05-26, 2010-05-27, 2010-05-28]
                def get_moving_average_on_date(field, date, days)
                    date_index = dates.index(date)
                    date_range = dates.reverse[dates.count-1 - date_index, days]
                    rcs = date_range.collect{ |date|
                        @game_scores_by_date[date].send(field)
                    }
                    rcs.average
                end
            end

            class BattersCollection
                def initialize
                    @batters = {}
                end

                def has_batter?(name)
                    @batters.has_key?(name)
                end

                def [](name)
                    @batters[name]
                end

                def []=(name, value)
                    @batters[name] = value
                end

                def moving_average_grid(field, days)
                    grid = MLB::Datafeed::Grid.new
                    @batters.keys.each do |name|
                        @batters[name].dates.each do |date|
                            grid.set(name, date.strftime("%m/%d/%Y"), @batters[name].get_moving_average_on_date(field, date, days))
                        end
                    end
                    return grid
                end

                def moving_average_xml(field, days)
                    xml = MLB::Datafeed::XmlOutput.new
                    @batters.keys.each do |name|
                        stats = []
                        @batters[name].dates.each do |date|
                            stats << { :date => date.strftime("%m/%d/%Y"), :stat => @batters[name].get_moving_average_on_date(field, date, days) }
                        end
                        xml.set(name, stats)
                    end
                    return xml
                end
            end
        end
    end
end
