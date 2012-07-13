class Time
  # Since the length of months and years aren't constant,
  # we use the averages. These also act as sort of 'magic
  # numbers' for the relative Time methods
  AVERAGE_MONTH = 2628000
  AVERAGE_YEAR  = 31540000
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
    Time.at(self)
  end

  def minutes
    Time.at(self * 60)
  end

  def hours
    Time.at(self * 3600)
  end

  def days
    Time.at(self * 86400)
  end

  def weeks
    Time.at(self * 604800)
  end

  def months
    Time.at(self * Time::AVERAGE_MONTH)
  end

  def years
    Time.at(self * Time::AVERAGE_YEAR)
  end

  alias_method :second,  :seconds
  alias_method :minute,  :minutes
  alias_method :hour,    :hours
  alias_method :day,     :days
  alias_method :week,    :weeks
  alias_method :month,   :months
  alias_method :year,    :years
end
