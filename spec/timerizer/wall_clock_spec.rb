require "spec_helper"

RSpec.describe Timerizer::WallClock do
  it "can be created" do
    Timerizer::WallClock.new(12, 30, :pm)
    Timerizer::WallClock.new(23, 30)
  end

  it "can be created from a string" do
    expect(
      Timerizer::WallClock.from_string("9:00 PM")
    ).to eq(Timerizer::WallClock.new(9, 00, :pm))

    expect(
      Timerizer::WallClock.from_string("13:00")
    ).to eq(Timerizer::WallClock.new(13, 00))

    expect(
      Timerizer::WallClock.from_string("12:00 PM")
    ).to eq(Timerizer::WallClock.new(12, 00, :pm))

    expect(
      Timerizer::WallClock.from_string("23:34:45")
    ).to eq(Timerizer::WallClock.new(23, 34, 45))

    expect(
      Timerizer::WallClock.from_string("11:00:01 PM")
    ).to eq(Timerizer::WallClock.new(11, 00, 01, :pm))
  end

  it "can apply a time on a day" do
    date = Date.new(2000, 1, 1)
    expect(
      Timerizer::WallClock.new(9, 00, :pm).on(date)
    ).to eq(Time.new(2000, 1, 1, 21))
  end

  it "can be initialized from a hash of values" do
    date = Date.new(2000, 1, 1)
    expect(
      Timerizer::WallClock.new(second: 30*60).on(date)
    ).to eq(Time.new(2000, 1, 1, 0, 30))
  end

  it "can be converted from an integer" do
    time = Timerizer::WallClock.new(21, 00)

    expect(
      Timerizer::WallClock.new(time.to_i)
    ).to eq(Timerizer::WallClock.new(9, 00, :pm))
  end

  it "can return its components" do
    time = Timerizer::WallClock.new(5, 35, 45, :pm)
    expect(time.hour).to eq(17)
    expect(time.hour(:twenty_four_hour)).to eq(17)
    expect(time.hour(:twelve_hour)).to eq(5)
    expect(time.minute).to eq(35)
    expect(time.second).to eq(45)
    expect(time.meridiem).to eq(:pm)

    expect(time.in_seconds).to eq((17*3600) + (35*60) + 45)
    expect(time.in_minutes).to eq((17*60) + 35)
    expect(time.in_hours).to eq(17)

    expect do
      time.hour(:thirteen_hour)
    end.to raise_error ArgumentError
  end

  it "raises an error for invalid wallclock times" do
    expect do
      Timerizer::WallClock.new(13, 00, :pm)
    end.to raise_error(Timerizer::WallClock::TimeOutOfBoundsError)

    expect do
      Timerizer::WallClock.new(24, 00, 00)
    end.to raise_error(Timerizer::WallClock::TimeOutOfBoundsError)

    expect do
      Timerizer::WallClock.new(0, 60)
    end.to raise_error(Timerizer::WallClock::TimeOutOfBoundsError)
  end

  it "can be converted to a `Duration`" do
    expect(
      Timerizer::WallClock.new(5, 30, 27, :pm).to_duration
    ).to eq(17.hours 30.minutes 27.seconds)
  end

  describe "#to_s" do
    before do
      @time = Timerizer::WallClock.new(5, 30, 27, :pm)
    end

    it "can be converted to a 12-hour time string" do
      expect(@time.to_s).to eq("5:30:27 PM")
      expect(@time.to_s(:twelve_hour)).to eq("5:30:27 PM")
      expect(@time.to_s(:twelve_hour, use_seconds: false)).to eq("5:30 PM")
      expect(@time.to_s(:twelve_hour, include_meridiem: false)).to eq("5:30:27")

      expect(
        @time.to_s(
          :twelve_hour,
          include_meridiem: false,
          use_seconds: false
        )
      ).to eq("5:30")
    end

    it "can be converted to a 24-hour time string" do
      expect(@time.to_s(:twenty_four_hour)).to eq("17:30:27")
      expect(
        @time.to_s(:twenty_four_hour, use_seconds: false)
      ).to eq("17:30")
    end

    it "zero-pads units" do
      time = Timerizer::WallClock.new(0, 00, 00)
      expect(time.to_s(:twelve_hour)).to eq("12:00:00 PM")
      expect(time.to_s(:twenty_four_hour)).to eq("0:00:00")

      expect(time.to_s(:twelve_hour, use_seconds: false)).to eq("12:00 PM")
      expect(time.to_s(:twenty_four_hour, use_seconds: false)).to eq("0:00")
    end
  end
end
