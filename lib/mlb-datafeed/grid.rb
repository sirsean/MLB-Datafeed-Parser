require "builder"

module MLB
    module Datafeed
        class Grid
            def initialize
                @column_keys = []
                @matrix = {}
            end

            def set(row_key, col_key, value)
                if @column_keys.index(col_key) == nil
                    @column_keys.push(col_key)
                    @column_keys = @column_keys.uniq.sort
                end

                if @matrix[row_key] == nil
                    @matrix[row_key] = {}
                end
                @matrix[row_key][col_key] = value
            end

            def write_csv(filename)
                puts "Writing CSV to #{filename}"
                # print the first row, which are the column keys
                open(filename, "wb"){ |file|
                    first_row = "\"\"," + @column_keys.sort.collect{|d| "\"#{d.to_s}\""}.join(",")

                    file.write(first_row + "\n")

                    @matrix.keys.select{ |row_key|
                        # if a player never played during this stretch of games, we want to omit them completely
                        row = []
                        @column_keys.each{ |col_key|
                            if !@matrix[row_key][col_key].nil? and !@matrix[row_key][col_key].to_s.empty?
                                row.push(@matrix[row_key][col_key])
                            end
                        }
                        !row.empty? and row.sum > 0
                    }.collect{ |row_key|
                        row = [ "\"#{row_key}\"" ]
                        @column_keys.each{ |col_key|
                            value = @matrix[row_key][col_key]
                            # if they didn't play, set their performance to 0 for the day
                            if value.to_s.empty?
                                value = ""
                            end
                            row.push("\"#{value}\"")
                        }
                        row
                    }.each{ |row|
                        file.write(row.join(",") + "\n")
                    }
                }
            end
        end

        class XmlOutput
            def initialize
                @batters = {}
            end

            def set(name, stats)
                @batters[name] = stats
            end

            def write(filename)
                puts "Writing XML to #{filename}"
                xml = Builder::XmlMarkup.new
                xml.batters do |batters|
                    @batters.keys.each do |name|
                        batters.batter(:name => name) do |b|
                            @batters[name].each do |stat|
                                b.stat(:date => stat[:date], :value => stat[:stat])
                            end
                        end
                    end
                end
                open(filename, "wb") do |file|
                    file.write(xml.target!)
                end
            end
        end
    end
end
