require "ftools"
require "lib/mlb-datafeed"

task :latest do
    reader = MLB::Datafeed::LocalFileReader.new

    latest = reader.latest_downloaded_date

    puts latest.strftime("%Y-%m-%d") unless latest.nil?
end

task :download do
    File.makedirs("xml")

    reader = MLB::Datafeed::LocalFileReader.new
    start_date = reader.latest_downloaded_date + 86400
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

task :parse_team, :start_date, :team do |t, args|
    team = args[:team]
    match = /(\d+)-(\d+)-(\d+)/.match(args[:start_date])
    start_date = Time.local(match[1], match[2], match[3])

    parser = MLB::Datafeed::Parser.new(
        :team => team,
        :start_date => start_date
    )

    batters = parser.parse

    File.makedirs("output")
    batters.moving_average_grid("woba", 10).write_csv("output/moving_average_#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}.csv")
end

task :parse_players, :start_date, :players do |t, args|
    match = /(\d+)-(\d+)-(\d+)/.match(args[:start_date])
    start_date = Time.local(match[1], match[2], match[3])
    players = args[:players].split(":")

    parser = MLB::Datafeed::Parser.new(
        :start_date => start_date,
        :players => players
    )

    batters = parser.parse

    File.makedirs("output")
    batters.moving_average_grid("woba", 10).write_csv("output/moving_average_#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}.csv")
end

