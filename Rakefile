require "rubygems"
require "ftools"
require "lib/mlb-datafeed"

task :default => :latest
task :latest do
    reader = MLB::Datafeed::LocalFileReader.new

    latest = reader.latest_downloaded_date

    puts latest.strftime("%Y-%m-%d") unless latest.nil?
end

task :download do
    File.makedirs("xml")

    reader = MLB::Datafeed::LocalFileReader.new
    latest_date = reader.latest_downloaded_date
    start_date = latest_date + 86400 unless latest_date.nil?
    if start_date.nil?
        start_date = Time.local(Time.now.year, 1, 1)
    end
    end_date = Time.now - 86400

    current_date = start_date
    while current_date <= end_date
        downloader = MLB::Datafeed::Downloader.new(current_date)
        game_ids = downloader.game_ids

        game_ids.each do |game_id|
            downloader.file_contents(game_id)
        end

        current_date += 86400
    end
end

task :parse_team, :start_date, :team, :type do |t, args|
    team = args[:team]
    match = /(\d+)-(\d+)-(\d+)/.match(args[:start_date])
    start_date = Time.local(match[1], match[2], match[3])
    case args[:type]
    when "xml"
        type = :xml
    else
        type = :csv
    end

    parser = MLB::Datafeed::Parser.new(
        :team => team,
        :start_date => start_date
    )

    batters = parser.parse

    File.makedirs("output")
    case type
    when :csv
        batters.moving_average_grid("woba", 10).write_csv("output/moving_average_#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}.csv")
    when :xml
        batters.moving_average_xml("woba", 10).write("output/moving_average_#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}.xml")
    end
end

task :parse_players, :start_date, :players, :type do |t, args|
    match = /(\d+)-(\d+)-(\d+)/.match(args[:start_date])
    start_date = Time.local(match[1], match[2], match[3])
    players = args[:players].split(":")
    case args[:type]
    when "xml"
        type = :xml
    else
        type = :csv
    end

    parser = MLB::Datafeed::Parser.new(
        :start_date => start_date,
        :players => players
    )

    batters = parser.parse

    File.makedirs("output")
    case type
    when :csv
        batters.moving_average_grid("woba", 10).write_csv("output/moving_average_#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}.csv")
    when :xml
        batters.moving_average_xml("woba", 10).write("output/moving_average_#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}.xml")
    end
end

