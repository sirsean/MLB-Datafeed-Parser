require 'rexml/document'
require 'date'
require 'grid'

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

class BatterGameScore
    attr_reader :name, :date
    def initialize(date, elem)
        @date = date
        @name = elem.attributes['name']
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

    def add_game_score(game_score)
        @game_scores.push(game_score)
        @game_scores_by_date[game_score.date] = game_score
    end

    def dates
        @game_scores_by_date.keys.sort
    end

    # get the <days> moving average as of <date>
    # so if date=2010-05-28 and days=5, you'd get the 5-day moving average as of May 28, or the average of the player's performance on [2010-05-24, 2010-05-25, 2010-05-26, 2010-05-27, 2010-05-28]
    def get_moving_average_on_date(date, days)
        date_index = dates.index(date)
        date_range = dates.reverse[dates.count-1 - date_index, days]
        rcs = date_range.collect{ |date|
            @game_scores_by_date[date].rc
        }
        rcs.average
    end
end

def parse_date_from_filename(filename)
    regex = /.*gid_(\d+)_(\d+)_(\d+)_.*/.match(filename)
    Date.new(regex[1].to_i, regex[2].to_i, regex[3].to_i)
end

# get all the files in the downloads directory
boxscores = Dir.glob("boxscores/*.xml")

batters = {}
batter_scores = {}
grid = Grid.new
boxscores.each{ |filename|
    date = parse_date_from_filename(filename)
    team_flag = 'home'
    doc = REXML::Document.new(File.read(filename))
    doc.elements.each("boxscore"){ |elem|
        home_team_code = elem.attributes['home_team_code']
        away_team_code = elem.attributes['away_team_code']
        if (home_team_code == 'min')
            team_flag = 'home'
        elsif away_team_code == 'min'
            team_flag = 'away'
        end
    }
    doc.elements.collect("boxscore/batting[@team_flag='#{team_flag}']/batter"){ |elem|
        BatterGameScore.new(date, elem)
    }.each { |game_score|
        puts "Date: #{game_score.date}; Batter: #{game_score.name}, wOBA: #{game_score.woba}"
        if not batter_scores[game_score.name]
            batter_scores[game_score.name] = []
        end
        batter_scores[game_score.name].push(game_score)
        if not batters[game_score.name]
            batters[game_score.name] = Batter.new(game_score.name)
        end
        batters[game_score.name].add_game_score(game_score)
        grid.set(game_score.name, game_score.date, game_score.rc)
    }
}

batters_to_keep = ["Span", "Hudson, O", "Mauer", "Morneau", "Cuddyer", "Kubel", "Thome", "Hardy", "Young, D", "Punto"]
    
rc_moving_average_grid = Grid.new
batters.keys.select{ |key|
    !batters_to_keep.index(key).nil?
}.each{ |key|
    batter = batters[key]
    puts batter.name
    batter.dates.each{ |date|
        rc_moving_average_grid.set(batter.name, date, batter.get_moving_average_on_date(date, 10))
    }
}

grid.write_csv("output.csv")
puts File.read("output.csv")

rc_moving_average_grid.write_csv("moving_average.csv")
puts File.read("moving_average.csv")
