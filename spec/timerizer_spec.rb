require_relative '../lib/timerizer'

describe RelativeTime do
  context "given an existing time" do
    before :all do
      @time = Time.new(2000, 1, 1, 3, 45, 00)
    end

    it "calculates a new time before itself" do
      5.minutes.before(@time).should == Time.new(2000, 1, 1, 3, 40, 00)
      5.months.before(@time).should == Time.new(1999, 8, 1, 3, 45, 00)
    end

    it "calculates a new time after itself" do
      5.minutes.after(@time).should == Time.new(2000, 1, 1, 3, 50, 00)
      5.months.after(@time).should == Time.new(2000, 6, 1, 3, 45, 00)
    end
  end

  context "given an odd time case" do
    it "properly calculates the time before it" do
      end_of_march = Time.new(2000, 3, 31, 3, 45, 00)
      1.month.before(end_of_march).should == Time.new(2000, 2, 29, 3, 45, 00)
    end

    it "properly calculates the time after it" do
      end_of_january = Time.new(2000, 1, 31, 3, 45, 00)
      1.month.after(end_of_january).should == Time.new(2000, 2, 29, 3, 45, 00)
    end
  end

  context "#to_s" do
    it "converts all units into a string" do
      (1.hour 3.minutes 4.seconds).to_s.should ==
        "1 hour, 3 minutes, 4 seconds"
    end

    it "converts units into a micro syntax" do
      (1.hour 3.minutes 4.seconds).to_s(:micro).should ==
        "1h"
    end

    it "converts units into a medium syntax" do
      (1.hour 3.minutes 4.seconds).to_s(:medium).should ==
        "1hr 3min"
    end
  end

  it "can average from second units to month units" do
    five_weeks = {
      :seconds => 3024000,
      :average => {:seconds => 394254, :months => 1}
    }

    5.weeks.get(:seconds).should == five_weeks[:seconds]

    average = 5.weeks.average!
    average.get(:seconds).should == five_weeks[:average][:seconds]
    average.get(:months).should == five_weeks[:average][:months]
  end

  it "can unaverage from month units to second units" do
    two_months = {
      :months => 2,
      :unaverage => {:seconds => 5259492, :months => 0}
    }

    2.months.get(:months).should == two_months[:months]

    unaverage = 2.months.unaverage!

    unaverage.get(:seconds).should == two_months[:unaverage][:seconds]
    unaverage.get(:months).should == two_months[:unaverage][:months]
  end

  it "can compare two RelativeTimes" do
    1.minute.should == 1.minute
    1.minute.should_not == 1.hour
  end
end

describe WallClock do
  it "can apply a time on a day" do
    date = Date.new(2000, 1, 1)
    WallClock.new(9, 00, :pm).on(date).should == Time.new(2000, 1, 1, 21)
  end

  it "can be initialize from a hash of values" do
    date = Date.new(2000, 1, 1)
    WallClock.new(:second => 30*60).on(date).should == Time.new(2000, 1, 1, 0, 30)
  end

  it "raises an error for invalid wallclock times" do
    expect do
      WallClock.new(13, 00, :pm)
    end.to raise_error(WallClock::TimeOutOfBoundsError)

    expect do
      WallClock.new(24, 00, 00)
    end.to raise_error(WallClock::TimeOutOfBoundsError)

    expect do
      WallClock.new(0, 60)
    end.to raise_error(WallClock::TimeOutOfBoundsError)
  end
end

describe Time do
  it "can be added or subtracted to RelativeTime" do
    time = Time.new(2000, 1, 1, 3, 45, 00)
    (time + 5.minutes).should == Time.new(2000, 1, 1, 3, 50, 00)
    (time - 5.minutes).should == Time.new(2000, 1, 1, 3, 40, 00)
  end

  it "can be converted to a Date object" do
    time = Time.new(2000, 1, 1, 11, 59, 00)
    time.to_date.should == Date.new(2000, 1, 1)
  end

  it "calculates the time between two Times" do
    time = 1.minute.ago
    Time.until(1.minute.from_now).in_seconds.should be_within(1.0).of(60)
    Time.since(1.hour.ago).in_seconds.should be_within(1.0).of(3600)

    Time.between(1.minute.ago, 2.minutes.ago).in_seconds.should be_within(1.0).of(60)
    Time.between(Date.yesterday, Date.tomorrow).in_seconds.should be_within(1.0).of(2.days.in_seconds)

    lambda do
      Time.until(1.minute.ago)
    end.should raise_error(Time::TimeIsInThePastError)

    lambda do
      Time.since(Date.tomorrow)
    end.should raise_error(Time::TimeIsInTheFutureError)
  end
end

describe Date do
  it "can be converted to a Time object" do
    date = Date.new(2000, 1, 1)
    date.to_time.should == Time.new(2000, 1, 1)
  end

  it "returns the number of days in a month" do
    Date.new(2000, 1).days_in_month.should == 31
    Date.new(2000, 2).days_in_month.should == 29
    Date.new(2001, 2).days_in_month.should == 28
  end

  it "returns the date yesterday and tomorrow" do
    yesterday = 1.day.ago.to_date
    tomorrow = 1.day.from_now.to_date

    Date.yesterday.should == yesterday
    Date.tomorrow.should == tomorrow
  end
end

describe Fixnum do
  it "makes RelativeTime objects" do
    1.minute.get(:seconds).should == 60
    3.hours.get(:seconds).should == 10800
    5.days.get(:seconds).should == 432000
    4.years.get(:months).should == 48

    relative_time = 1.second 2.minutes 3.hours 4.days 5.weeks 6.months 7.years
    relative_time.get(:seconds).should == 3380521
    relative_time.get(:months).should == 90
  end
end
