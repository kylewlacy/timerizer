class RelativeTime
  @@in_seconds = {
      :second => 1,
      :minute => 60,
      :hour => 3600,
      :day => 864000,
      :week => 604800
  }

  @@in_months = {
    :month => 1,
    :year => 12,
    :decade => 120,
    :century => 1200,
    :millenium => 12000
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
    time = time - @seconds

    new_month = time.month - @months
    new_year = time.year
    while new_month < 1
      new_month += 12
      new_year -= 1
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
    time = time + @seconds

    new_month = time.month + @months
    new_year = time.year
    while new_month > 12
      new_year += 1
      new_month -= 12
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
end

class Time
  # Since the length of months and years aren't constant,
  # we use the averages. These also act as sort of 'magic
  # numbers' for the relative Time methods
  AVERAGE_MONTH = 2628000
  AVERAGE_YEAR  = 31540000

  add = instance_method(:+)
  define_method(:+) do |time|
    if(time.class == RelativeTime)
      time + self
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

  def relative?
    @relative ||= false
  end

  def before(time)
    if(self.to_i % AVERAGE_MONTH == 0)
      new_month = time.month - (self.to_i / AVERAGE_MONTH)
      new_year = time.year
      while new_month < 1 do
        new_month += 12
        new_year -= 1
      end

      if not(Time.day_exists_in_month?(time.day, new_month, new_year))
        return Time.new(new_year, new_month, Time.days_in_month(new_month, new_year), time.hour, time.min, time.sec, time.utc_offset)
      else
        return Time.new(new_year, new_month, time.day, time.hour, time.min, time.sec, time.utc_offset)
      end
    elsif(self.to_i % AVERAGE_YEAR == 0)
      new_year = (self.to_i / AVERAGE_YEAR) + time.year
      if not(time.leap_day?)
        return Time.new(new_year, time.month, time.day, time.hour, time.min, time.sec, time.utc_offset)
      else
        return Time.new(new_year, time.month + 1, 1, time.hour, time.min, time.sec, time.utc_offset)
      end
    end
    Time.at(time.to_i - self.to_i)
  end

  def ago
    self.before(Time.now)
  end

  def after(time)
    if(self.to_i % AVERAGE_MONTH == 0)
      new_month = (self.to_i / AVERAGE_MONTH) + time.month
      new_year = time.year
      while new_month > 12 do
        new_month -= 12
        new_year += 1
      end

      if not(Time.day_exists_in_month?(time.day, new_month, new_year))
        return Time.new(new_year, new_month, Time.days_in_month(new_month, new_year), time.hour, time.min, time.sec, time.utc_offset)
      else
        return Time.new(new_year, new_month, time.day, time.hour, time.min, time.sec, time.utc_offset)
      end
    elsif(self.to_i % AVERAGE_YEAR == 0)
      new_year = (self.to_i / AVERAGE_YEAR) + time.year
      if not(time.leap_day?)
        return Time.new(new_year, time.month, time.day, time.hour, time.min, time.sec, time.utc_offset)
      else
        return Time.new(new_year, time.month + 1, 1, time.hour, time.min, time.sec, time.utc_offset)
      end
    end
    Time.at(time.to_i + self.to_i)
  end

  def from_now
    self.after(Time.now)
  end

  def self.day_exists_in_month?(day, month, year = Time.at(0).utc.year)
    Time.days_in_month(month, year) >= day
  end

  def self.days_in_month(month, year = Time.at(0).utc.year)
    number_of_days = [31, (not leap_year?(year)) ? 28 : 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    number_of_days.fetch(month - 1)
  end

  def self.leap_year?(year)
    (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
  end

  def leap_year?
    Time.leap_year?(self.year)
  end

  def leap_day?
    self.month == 2 && self.day == 29
  end
end

class Fixnum
  def seconds
    Time.relative(self)
  end

  def minutes
    Time.relative(self * 60)
  end

  def hours
    Time.relative(self * 3600)
  end

  def days
    Time.relative(self * 86400)
  end

  def weeks
    Time.relative(self * 604800)
  end

  def months
    Time.relative(self * Time::AVERAGE_MONTH)
  end

  def years
    Time.relative(self * Time::AVERAGE_YEAR)
  end

  alias_method :second,  :seconds
  alias_method :minute,  :minutes
  alias_method :hour,    :hours
  alias_method :day,     :days
  alias_method :week,    :weeks
  alias_method :month,   :months
  alias_method :year,    :years
end
