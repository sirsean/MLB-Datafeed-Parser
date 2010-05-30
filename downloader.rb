require 'rexml/document'
require 'net/http'
require 'ftools'
require 'Date'

class Date
    def month_zero_prefix
        if self.month < 10
            return "0#{self.month}"
        else
            return self.month
        end
    end

    def day_zero_prefix
        if self.day < 10
            return "0#{self.day}"
        else
            return self.day
        end
    end
end

def download_file(remote_filename)
    local_filename = "boxscores/" + remote_filename.split("/")[-2] + ".xml"
    Net::HTTP.start("gd2.mlb.com"){ |http|
        resp = http.get(remote_filename)
        open(local_filename, "wb"){ |file|
            file.write(resp.body)
        }
    }
end

def get_list_of_remote_filenames_by_date(date)
    base_path = "/components/game/mlb/year_#{date.year}/month_#{date.month_zero_prefix}/day_#{date.day_zero_prefix}/"
    links = []
    Net::HTTP.start("gd2.mlb.com"){ |http|
        resp = http.get(base_path)
        doc = REXML::Document.new(resp.body)
        doc.elements.each("html/body/ul/li/a"){ |elem|
            if elem.attributes["href"] =~ /gid_.*/
                links.push(base_path + elem.attributes["href"] + "boxscore.xml")
            end
        }
    }
    return links
end

# make sure the download directory exists
File.makedirs("boxscores")

# get the filenames on a particular day
first = Date.new(2010, 5, 29)
last = Date.new(2010, 5, 29)

x = first
while x <= last
    filenames = get_list_of_remote_filenames_by_date(x)
    # figure out which of the files are twins games
    filenames.select{ |f| f =~ /gid_.*_minmlb_.*/ }.each{ |f| 
        puts "Downloading #{f}"
        download_file(f)
    }
    x += 1
end

puts "Done"
