require 'date'

class RelativeTime
  @@in_seconds = {
      :second => 1,
      :minute => 60,
      :hour => 3600,
      :day => 86400,
      :week => 604800
  }

  @@in_months = {
    :month => 1,
    :year => 12,
    :decade => 120,
    :century => 1200,
    :millenium => 12000
  }

  @@average_seconds = {
    :month => 2628000,
    :year => 31540000
  }

  def initialize(count = 0, unit = :second)
    @seconds = 0
    @months = 0

    if(@@in_seconds.has_key?(unit))
      @seconds = count * @@in_seconds.fetch(unit)
    elsif(@@in_months.has_key?(unit))
      @months = count * @@in_months.fetch(unit)
    end
  end

  def before(time)
    time = time.to_time - @seconds

    new_month = time.month - @months
    new_year = time.year
    while new_month < 1
      new_month += 12
      new_year -= 1
    end
    if(Date.valid_date?(new_year, new_month, time.day))
      new_day = time.day
    else
      new_day = Date.days_in_month(new_month)
    end

    new_time = Time.new(
      new_year, new_month, time.day,
      time.hour, time.min, time.sec
    )
    Time.at(new_time.to_i, time.nsec/1000)
  end

  def ago
    self.before(Time.now)
  end

  def after(time)
    time = time.to_time + @seconds

    new_year = time.year
    new_month = time.month + @months
    while new_month > 12
      new_year += 1
      new_month -= 12
    end
    if(Date.valid_date?(new_year, new_month, time.day))
      new_day = time.day
    else
      new_month += 1
      new_day = 1
    end


    new_time = Time.new(
      new_year, new_month, time.day,
      time.hour, time.min, time.sec
    )
    Time.at(new_time.to_i, time.nsec/1000.0)
  end

  def from_now
    self.after(Time.now)
  end

  def in_years
    @months / @@in_months[:year]
  end

  def years
    self.in_years
  end

  def in_months
    @months / @@in_months[:month]
  end

  def months
    self.in_months - self.in_years.years.in_months
  end

  def average!
    years = self.in_years
    months = self.in_months - years.years.in_months
    @seconds += (
      (@@average_seconds[:month] * months) +
      (@@average_seconds[:year] * years)
    )
    @months = 0
  end

  def in_weeks
    @seconds / @@in_seconds[:week]
  end

  def weeks
    self.in_weeks
  end

  def in_days
    @seconds / @@in_seconds[:day]
  end

  def days
    self.in_days - self.in_weeks.weeks.in_days
  end

  def in_hours
    @seconds / @@in_seconds[:hour]
  end

  def hours
    self.in_hours - self.in_days.days.in_hours
  end

  def in_minutes
    @seconds / @@in_seconds[:minute]
  end

  def minutes
    self.in_minutes - self.in_hours.hours.in_minutes
  end

  def in_seconds
    @seconds / @@in_seconds[:second]
  end

  def seconds
    self.in_seconds - self.in_minutes.minutes.in_seconds
  end
end

class Time
  add = instance_method(:+)
  define_method(:+) do |time|
    if(time.class == RelativeTime)
      time.after(self)
    else
      add.bind(self).(time)
    end
  end

  subtract = instance_method(:-)
  define_method(:-) do |time|
    if(time.class == RelativeTime)
      time.before(self)
    else
      subtract.bind(self).(time)
    end
  end

  def to_date
    Date.new(self.year, self.month, self.day)
  end

  def to_time
    self
  end
end

class Date
  def days_in_month
    days_in_feb = (not self.leap?) ? 28 : 29
    number_of_days = [
      31,  days_in_feb,  31,  30,  31,  30,
      31,  31,           30,  31,  30,  31
    ]

    number_of_days.fetch(self.month - 1)
  end

  def to_date
    self
  end
end

class Fixnum
  def seconds
    RelativeTime.new(self, :second)
  end

  def minutes
    RelativeTime.new(self, :minute)
  end

  def hours
    RelativeTime.new(self, :hour)
  end

  def days
    RelativeTime.new(self, :day)
  end

  def weeks
    RelativeTime.new(self, :week)
  end

  def months
    RelativeTime.new(self, :month)
  end

  def years
    RelativeTime.new(self, :year)
  end

  alias_method :second,  :seconds
  alias_method :minute,  :minutes
  alias_method :hour,    :hours
  alias_method :day,     :days
  alias_method :week,    :weeks
  alias_method :month,   :months
  alias_method :year,    :years
end
