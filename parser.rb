require 'rexml/document'
require 'date'
require 'grid'

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
end

def parse_date_from_filename(filename)
    regex = /.*gid_(\d+)_(\d+)_(\d+)_.*/.match(filename)
    Date.new(regex[1].to_i, regex[2].to_i, regex[3].to_i)
end

# get all the files in the downloads directory
boxscores = Dir.glob("boxscores/*.xml")

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
    }.each { |batter|
        puts "Date: #{batter.date}; Batter: #{batter.name}, wOBA: #{batter.woba}"
        if not batter_scores[batter.name]
            batter_scores[batter.name] = []
        end
        batter_scores[batter.name].push(batter)
        grid.set(batter.name, batter.date, batter.woba)
    }
}

batter_scores.keys.each{|name|
    scores = batter_scores[name]
    scores.each{ |score|
        puts "#{name}: #{score.date}, wOBA: #{score.woba}"
    }
}

grid.write_csv("output.csv")
puts File.read("output.csv")
