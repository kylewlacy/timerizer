require "spec_helper"

RSpec.describe Time do
  it "can be added or subtracted to Duration" do
    time = Time.new(2000, 1, 1, 3, 45, 00)
    expect(time + 5.minutes).to eq(Time.new(2000, 1, 1, 3, 50, 00))
    expect(time - 5.minutes).to eq(Time.new(2000, 1, 1, 3, 40, 00))
  end

  it "can be converted to a Date object" do
    time = Time.new(2000, 1, 1, 11, 59, 00)
    expect(time.to_date).to eq(Date.new(2000, 1, 1))
  end

  it "calculates the time between two Times" do
    time = 1.minute.ago
    expect(Time.until(1.minute.from_now).get(:seconds)).to be_within(1.0).of(60)
    expect(Time.since(1.hour.ago).get(:seconds)).to be_within(1.0).of(3600)

    expect(
      Time.between(1.minute.ago, 2.minutes.ago).get(:seconds)
    ).to be_within(1.0).of(60)

    expect(
      Time.between(Date.yesterday, Date.tomorrow).get(:seconds)
    ).to be_within(1.0).of(2 * 24 * 60 * 60)

    expect do
      Time.until(1.minute.ago)
    end.to raise_error(Time::TimeIsInThePastError)

    expect do
      Time.since(Date.tomorrow)
    end.to raise_error(Time::TimeIsInTheFutureError)
  end

  it "can be converted to a WallClock time" do
    time = Time.new(2000, 1, 1, 17, 58, 04)
    expect(time.to_wall).to eq(Timerizer::WallClock.new(5, 58, 04, :pm))
  end
end

RSpec.describe Date do
  it "can be converted to a Time object" do
    date = Date.new(2000, 1, 1)
    expect(date.to_time).to eq(Time.new(2000, 1, 1))
  end

  it "returns the number of days in a month" do
    expect(Date.new(2000, 1).days_in_month).to eq(31)
    expect(Date.new(2000, 2).days_in_month).to eq(29)
    expect(Date.new(2001, 2).days_in_month).to eq(28)
  end

  it "returns the date yesterday and tomorrow" do
    yesterday = 1.day.ago.to_date
    tomorrow = 1.day.from_now.to_date

    expect(Date.yesterday).to eq(yesterday)
    expect(Date.tomorrow).to eq(tomorrow)
  end

  it "returns the time on a given date" do
     date = Date.new(2000, 1, 1)
     time = Timerizer::WallClock.new(5, 00, :pm)
     expect(date.at(time)).to eq(Time.new(2000, 1, 1, 17))
  end
end

RSpec.describe Integer do
  it "creates `Duration`s" do
    expect(1.minute.get(:seconds)).to eq(60)
    expect(3.hours.get(:seconds)).to eq(10800)
    expect(5.days.get(:seconds)).to eq(432000)
    expect(4.years.get(:months)).to eq(48)

    duration = 1.second 2.minutes 3.hours 4.days 5.weeks 6.months 7.years
    expect(duration.get(:seconds)).to eq(3380521)
    expect(duration.get(:months)).to eq(90)
  end

  it "defines helpers for all units" do
    Timerizer::Duration::UNIT_ALIASES.each do |unit_name, _|
      duration = 1.send(unit_name)
      expect(duration).to eq(Timerizer::Duration.new(unit_name => 1))
    end
  end
end
