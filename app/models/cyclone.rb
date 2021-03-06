class Cyclone < ActiveRecord::Base
  belongs_to :cyclone_date
  belongs_to :path
  has_many :historical_weather

  options = { :namespace => "app_v1", :compress => true }
  @dc = Dalli::Client.new  #('localhost:11211', options)

  scope :many_cyclone_map_data, -> { select('start_lat', 'start_long', 'stop_lat', 'stop_long', 'cyclones.id', 'f_scale', 'cyclones.cyclone_date_id', 'fatalities', 'crop_loss', 'property_loss', 'injuries', 'cyclones.path_id') }
  scope :complete_cyclone_tracks, -> { joins(:path).where('paths.complete_track') }
  scope :strongest_cyclones_first, -> { order(f_scale: :desc) }
  scope :index_map, -> { complete_cyclone_tracks.strongest_cyclones_first.limit(500).many_cyclone_map_data }
  scope :deadly_cyclones, -> { where('fatalities >= 1') }
  scope :deadliest_cyclones_first, -> { order(fatalities: :desc) }
  scope :costliest_cyclones_first, -> { order(property_loss: :desc) }
  scope :scale_5_cyclones, -> { where('f_scale = 5') }
  scope :same_day, ->(id_obj) { where(cyclone_date_id: Cyclone.find(id_obj["id"]).cyclone_date_id) }

  def self.historical_data(id)

    cyclone = Cyclone.find(id)

    if cyclone.historical_weather.length > 0
      hist_weather_db_call(cyclone)
    else
      hist_weather_api_call(cyclone)
    end
  end

  def self.radius_search(params)
    city = params['city'].gsub(' ', '+')
    state = params['state'].downcase
    radius = params['radius']
    response = Unirest.get('https://maps.googleapis.com/maps/api/geocode/json?address=' + city + ',+' + state + '&sensor=false&key=' + ENV["GOOGLE_GEO_KEY"])
    lat = response.body['results'][0]['geometry']['location']['lat']
    lng = response.body['results'][0]['geometry']['location']['lng']

    # .select won't return an active record model. Rewrite it?
    cyclone = Cyclone.complete_cyclone_tracks
    cyclone = cyclone.where(state: state) if state.length == 2

    cyclone.select{ |cyclone| cyclone.radius_search_results(lat, lng, radius) }
  end

  def radius_search_results(xc, yc, radius)
    # Start Point
    x1 = self.start_lat
    y1 = self.start_long
    # Check if the start point is in the circle
    # start_dist = Math.sqrt((x1-xc)**2+(y1-yc)**2)*25/0.3617
    # return false if start_dist > 100
    return true if radius.to_f >= Math.sqrt((x1-xc)**2+(y1-yc)**2)*25/0.3617
    # Stop Point
    self.stop_lat == 0 ? x2 = x1 : x2 = self.stop_lat
    self.stop_long == 0 ? y2 = y1 : y2 = self.stop_long
    #Check if the stop point is in the circle
    # stop_dist = Math.sqrt((x2-xc)**2+(y2-yc)**2)*25/0.3617
    # return false if stop_dist > 100
    return true if radius.to_f >= Math.sqrt((x2-xc)**2+(y2-yc)**2)*25/0.3617
    # Slope of Tornado Path
    y2 == y1 ? m1 = 0 : m1 = (y2 - y1) / (x2 - x1)
    # Y Intercept of Tornado Path
    b1 = y1 - (m1 * x1)
    # X and Y Intercept Points between Tornado Path and Tangent Line from Circle Center
    m1 == 0 ? xi = x2 : xi = ((yc + (xc / m1) - b1) / (m1 - (1 / m1)))
    y2 == y1 ? yi = y2 : yi = ((m1 * xi) + b1)
    #Figure out if xi and yi is on the line segment path
    return false if xi > x1 && xi > x2
    return false if xi < x1 && xi < x2
    return false if yi > y1 && yi > y2
    return false if yi < y1 && yi < y2
    # Distance in degrees of the line from the Circle Center to the X,Y Intercept
    dist = Math.sqrt((xi - xc)**2 + (yi - yc)**2) * 25.0 / 0.3617
    # Return true if in the circle, false if out of the circle
    dist <= radius.to_f
  end

  def add_weather(data)
    add_weather_save(data["currently"], -9)

    data["hourly"]["data"].each_with_index do |hourly_weather, index|
      add_weather_save(hourly_weather, index)
    end
  end

  def add_weather_save(hourly_weather, hour)
    weather = self.historical_weather.new
    weather.temperature = hourly_weather["temperature"] if hourly_weather["temperature"]
    weather.pressure = hourly_weather["pressure"] if hourly_weather["pressure"]
    weather.wind_speed = hourly_weather["windSpeed"] if hourly_weather["windSpeed"]
    weather.wind_bearing = hourly_weather["windBearing"] if hourly_weather["windBearing"]
    weather.hour = hour
    weather.save
  end

  # Formats the results as the JSON we want
  def as_json(cyclones)
    if self.has_attribute?(:width)
      # Laziness variables for fewer db calls and less typing later
      all_avg = AvgCycloneData.find_by(year: "all")
      year_avg = AvgCycloneData.find_by(year: self.cyclone_date.year.to_s)
      # Setting up empty variables for the historical weather
      hourly = []
      currently = nil
      # binding.pry
      # Set all of the historical data if it exists, otherwise return nil and an empty array
      if touchdown = self.historical_weather.find_by(hour: -9)
        currently = {
          pressure: touchdown.pressure,
          windSpeed: touchdown.wind_speed,
          windBearing: touchdown.wind_bearing.to_i,
          temperature: touchdown.temperature
        }
        self.historical_weather.where('hour != -9').each do |hour_weather|
          hourly[hour_weather.hour] = {}
          hourly[hour_weather.hour]["windSpeed"] = hour_weather.wind_speed
          hourly[hour_weather.hour]["temperature"] = hour_weather.temperature
          hourly[hour_weather.hour]["pressure"] = hour_weather.pressure
          hourly[hour_weather.hour]["windBearing"] = hour_weather.wind_bearing.to_i
        end
      end
      {
        id: self.id,
        date: {
          day: self.cyclone_date.day,
          month: self.cyclone_date.month,
          year: self.cyclone_date.year,
          hour: self.hour,
          minute: self.minute,
          timeZone: self.time_zone
        },
        cycloneStrength: {
          fScale: self.f_scale,
          width: self.width
        },
        loss: {
          injuries: self.injuries,
          fatalities: self.fatalities,
          propertyLoss: self.property_loss,
          cropLoss: self.crop_loss
        },
        location: {
          startLat: self.start_lat,
          startLong: self.start_long,
          stopLat: self.stop_lat,
          stopLong: self.stop_long,
          distance: self.distance,
          state: self.state,
          countyCodeOne: self.county_code_one,
          countyCodeTwo: self.county_code_two,
          countyCodeThree: self.county_code_three,
          countyCodeFour: self.county_code_four,
          statesCrossed: self.path.states_crossed
        },
        path: {
          completeTrack: self.path.complete_track,
          segmentNum: self.path.segment_num
        },
        average: {
          all: {
            fatalities: all_avg.fatalities,
            propertyLoss: all_avg.property_loss,
            cropLoss: all_avg.crop_loss,
            injuries: all_avg.injuries,
            fScale: all_avg.f_scale,
            distance: all_avg.distance
          },
          year: {
            fatalities: year_avg.fatalities,
            propertyLoss: year_avg.property_loss,
            cropLoss: year_avg.crop_loss,
            injuries: year_avg.injuries,
            fScale: year_avg.f_scale,
            distance: year_avg.distance
          }
        },
        touchdownWeather: currently,
        historicalWeather: hourly
      }
    else
      {
        location: {
          startLat: self.start_lat,
          startLong: self.start_long,
          stopLat: self.stop_lat,
          stopLong: self.stop_long
        },
        cycloneStrength: {
          fScale: self.f_scale
        },
        id: self.id,
        date: {
          day: self.cyclone_date.day,
          month: self.cyclone_date.month,
          year: self.cyclone_date.year
        },
        loss: {
          fatalities: self.fatalities,
          propertyLoss: self.property_loss,
          cropLoss: self.crop_loss
        }
      }
    end
  end

  # This method takes the cyclone records and the params hash and uses the different types of
  # selectors on them using primarily .where, but also .joins.where for date and path values
  # Records determines the number of records to return and does so AFTER everything else is selected
  # only_map_data determines if the data is being pruned to only include data for plotting.
  # This is to reduce the amount of data being sent over if it is only be shown on a map.

  def self.selectors(params)
    @dc.fetch(params) {
      cyclone = Cyclone.includes(:cyclone_date, :historical_weather, :path) #.includes(:cyclone_date, :path, :historical_weather)
      @cyclone_limit = 500 #Set the default return value to 500 records
      @only_map_data = false #Set the default map_data return to be all parts of the record
      if params["selectors"]
        # @dc.fetch(params["selectors"]) {
          symbol = illegal_chars(params["selectors"])
          return {error: "#{symbol} in selectors is not allowed.", status: 400} if symbol
          #Split the selectors by the comma into inidividual key value pairs
          selectors = params["selectors"].split(',')
          selectors.each do |selector|
            cyclone = selector_splitter(cyclone, selector)
            return cyclone if cyclone.is_a?(Hash)
          end
          cyclone = cyclone.many_cyclone_map_data if @only_map_data
        # }
      end
      if params["search_name"]
        cyclone = search(cyclone, params)
        return cyclone if cyclone.is_a?(Hash)
        # binding.pry
      end
      #Selects the map data if needed, runs at the end to not break any other selectors
      if cyclone.class == Array
        # raise "It's an array!"
        cyclone = cyclone[0...@cyclone_limit] if cyclone.length > @cyclone_limit
      else
        # cyclone = cyclone.limit(@cyclone_limit)
        cyclone = Cyclone.includes(:cyclone_date, :historical_weather, :path).find_by_sql(cyclone.limit(@cyclone_limit).to_sql) #cyclone.limit(@cyclone_limit) #Finally, pulls the requested number of records (Default of 500)
      end

      cyclone = cyclone.to_json
    }
  end

  def self.search(cyclone, params)
    symbol = illegal_chars(params["search_name"])
    return {error: "#{symbol} in the search is not allowed.", status: 400} if symbol
    cyclone = searches(cyclone, params)
  end

private
  def self.illegal_chars(selectors)
    ["{","}","[","]","<",">","=","%","?","|","*","&","^","$","#","@","!"].each do |symbol|
      return symbol if selectors.include?(symbol)
    end
    return false
  end


  def self.searches(cyclone, params)
    begin
      if params["search_name"]
        # If it is a search that takes params, like radius_search, split the params up
        if params["search_name"].include? ","
          search_arg_obj = {}
          search_params = params["search_name"].split(",")
          search = search_params.shift # Pulls out the search name from the parameters
          search_params.each do |param|  # Go through and add the parameters to the arguments object
            split_param = param.split(":")
            search_arg_obj[split_param[0].downcase] = split_param[1]
          end
          cyclone = cyclone.send(search, search_arg_obj)
        else
          #If the search name ends in st, add _cyclones_first to it
          if params["search_name"][-2..-1] == "st"
            search = params["search_name"] + "_cyclones_first"
          else
            search = params["search_name"] + "_cyclones"
          end
          cyclone = cyclone.send(search)
        end
      end
      # p cyclone.first # Forces the NoMethodError to occur by causing the SQL query to run
    rescue NoMethodError
      return cyclone = {error: "#{search} is not a valid search term.", status: 400} if search
      return cyclone = {error: "#{search_name} is not a valid search term.", status: 400}
    end
    cyclone
  end

  def self.selector_splitter(cyclone, selector)
    split_selector = selector.split(':')
    key = 0
    value = 1
    # If a date selector, use the .joins.where
    if split_selector[key] == 'records' || split_selector[key] == 'record'
      @cyclone_limit = split_selector[value].to_i
    elsif split_selector[key] == 'state'
      cyclone = cyclone.where(state: split_selector[value].downcase)
    elsif split_selector[key] == "only_map_data"
      @only_map_data = split_selector[value]
    # If any other type of record, use the .where
    else
      cyclone = where_selector(cyclone, split_selector)
    end
    cyclone
  end

  def self.where_selector(cyclone, split_selector)
    begin
      key = 0
      value = 1
      if split_selector[value][-1] == '+'
        relational_op = ' >= '
        split_selector[value] = split_selector[value][0...-1]
      elsif split_selector[value][-1] == '-'
        relational_op = ' <= '
        split_selector[value] = split_selector[value][0...-1]
      else
        relational_op = ' = '
      end

      if split_selector[key] == 'month' || split_selector[key] == 'day' || split_selector[key] == 'year'
        cyclone = cyclone.joins(:cyclone_date).where(split_selector[key] + relational_op + split_selector[value])
      elsif split_selector[key] == 'complete_track' || split_selector == 'states_crossed'
        cyclone = cyclone.joins(:path).where(split_selector[key] + relational_op + split_selector[value])
      else
        cyclone = cyclone.where(split_selector[key] + relational_op + split_selector[value])
      end
      # p cyclone.first  #Used to force the ActiveRecord error catch below to work!!! Forces the Active Record Query to run
    rescue ActiveRecord::StatementInvalid => e
      return cyclone = {error: "#{split_selector[key]} is not a valid selector.", status: 400}
    end
    cyclone
  end

  def self.hist_weather_api_call(cyclone)
    month = cyclone.cyclone_date.month.to_s
    day = cyclone.cyclone_date.day.to_s
    hour = cyclone.hour.to_s
    minute = cyclone.minute.to_s
    # Format the time for the API call
    month = '0' + month if month.length == 1
    day = '0' + day if day.length == 1
    hour = '0' + hour if hour.length == 1
    minute = '0' + minute if minute.length == 1
    time = cyclone.cyclone_date.year.to_s + '-' + month + '-' + day + 'T' + hour + ':' + minute + ':00-0600'

    #2013-05-06T12:00:00-0400  <- Final time must be in this format for the Historical Data API call

    response = Unirest.get('https://api.forecast.io/forecast/'+ENV['FORECAST_IO_KEY'].to_s+'/'+cyclone.start_lat.to_s+','+cyclone.start_long.to_s + ',' + time,
      headers: { "Accept" => "application/json" })

    cyclone.add_weather(response.body)

    response.body
  end

  def self.hist_weather_db_call(cyclone)
    weather = cyclone.historical_weather
    location_data = {}
    location_data["hourly"] = {}
    location_data["hourly"]["data"] = []
    weather.each do |data_arr|
      location_data = self.get_weather(location_data, data_arr)
    end
    location_data
  end

  def self.get_weather(weather_obj, data_arr)
    if data_arr["hour"] == -9
      current = weather_obj["currently"] = {}
      current["temperature"] = data_arr["temperature"]
      current["pressure"] = data_arr["pressure"]
      current["windSpeed"] = data_arr["wind_speed"]
      current["windBearing"] = data_arr["wind_bearing"]
    else
      hour_data = weather_obj["hourly"]["data"]
      hour_data[data_arr["hour"]] = {}
      hour_data[data_arr["hour"]]["temperature"] = data_arr["temperature"]
      hour_data[data_arr["hour"]]["pressure"] = data_arr["pressure"]
      hour_data[data_arr["hour"]]["wind_speed"] = data_arr["wind_speed"]
      hour_data[data_arr["hour"]]["wind_bearing"] = data_arr["wind_bearing"]
    end
    weather_obj
  end
end
