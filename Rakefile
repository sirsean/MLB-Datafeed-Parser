require "ftools"
require "lib/mlb-datafeed"

task :latest do
    reader = MLB::Datafeed::LocalFileReader.new

    latest = reader.latest_downloaded_date

    puts latest.strftime("%Y-%m-%d")
end

task :download, :start_date, :end_date do |t, args|
    File.makedirs("xml")

    date_regex = /(\d+)-(\d+)-(\d+)/
    if args[:start_date].nil?
        start_date = Time.local(Time.now.year, 1, 1)
    else
        match = date_regex.match(args[:start_date])
        start_date = Time.local(match[1], match[2], match[3])
    end
    if args[:end_date].nil?
        end_date = Time.now - 86400
    else
        match = date_regex.match(args[:end_date])
        end_date = Time.local(match[1], match[2], match[3])
    end

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

task :parse, :team, :start_date, :players do |t, args|
    team = args["team"]
    match = /(\d+)-(\d+)-(\d+)/.match(args["start_date"])
    start_date = Time.local(match[1], match[2], match[3])
    players = args["players"].nil? ? nil : args["players"].split(":")

    parser = MLB::Datafeed::Parser.new(team, start_date, players)

    batters = parser.parse

    woba_moving_average_grid = MLB::Datafeed::Grid.new
    batters.keys.each do |name|
        batters[name].dates.each do |date|
            woba_moving_average_grid.set(name, date.strftime("%m/%d/%Y"), batters[name].get_moving_average_on_date("woba", date, 10))
        end
    end

    File.makedirs("output")
    csv_filename = "output/moving_average_#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}.csv"
    woba_moving_average_grid.write_csv(csv_filename)
end

