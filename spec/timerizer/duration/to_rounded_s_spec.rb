# frozen_string_literal: true

require "spec_helper"

require 'timerizer/duration'

RSpec.describe Timerizer::Duration do
  describe '#to_rounded_s' do
    describe 'passes all (adjusted) #to_s specs including' do
      it "converts all units into a string" do
        expect(
          (1.year 3.months).to_rounded_s(:long)
        ).to eq('1 year, 3 months')

        expect(
          (4.days 1.hour).to_rounded_s(:long)
        ).to eq('4 days, 1 hour')

        expect(
          (3.minutes 4.seconds).to_rounded_s
        ).to eq('3 minutes, 4 seconds')

        expect(
          (1000.years).to_rounded_s(:long)
        ).to eq("1000 years")

        expect(0.seconds.to_rounded_s).to eq("0 seconds")
        expect(0.minutes.to_rounded_s).to eq("0 seconds")
        expect(0.months.to_rounded_s).to eq("0 seconds")
        expect(0.years.to_rounded_s).to eq("0 seconds")
      end

      describe 'normalizes the string by default' do
        it 'for a single unit value' do
          expect(30.days.to_rounded_s).to eq("1 month")
        end

        it "normalizes the string by default" do
          input = (365 + 30 + 1).days
          expect(input.to_rounded_s).to eq('1 year, 1 month')
        end
      end

      it "converts units into a micro format" do
        expect(
          (1.hour 3.minutes 4.seconds).to_rounded_s(:micro)
        ).to eq("1h")

        expect(
          (1.year 3.months 4.days).to_rounded_s(:micro)
        ).to eq("1y")
      end

      it "converts units into a medium format" do
        expect(
          (1.hour 3.minutes 4.seconds).to_rounded_s(:short)
        ).to eq("1hr 3min")

        expect(
          (1.year 3.months 4.days).to_rounded_s(:short)
        ).to eq("1yr 3mo")
      end

      it "converts units using a user-defined format" do
        expect(
          (1.hour 3.minutes 4.seconds).to_rounded_s(
            units: {
              seconds: "second(s)",
              minutes: "minute(s)",
              hours: "hour(s)"
            },
            separator: ' ',
            delimiter: ' / '
          )
        ).to eq("1 hour(s) / 3 minute(s)")
      end

      it "uses user-defined options to override default format options" do
        expect(8.days.to_rounded_s(separator: "_")).to eq("1_week, 1_day")
        v = "1_week 1_day"
        expect(8.days.to_rounded_s(separator: "_", delimiter: " ")).to eq(v)
        expect(8.days.to_rounded_s(:micro, count: :all)).to eq("1w 1d")
      end
    end # describe 'passes all (adjusted) #to_s specs including'

    describe 'by default, rounds to two units when' do
      describe 'more than two units specified that are' do
        describe 'not subject to rounding and' do
          it 'all adjacent' do
            input = (2.hours 3.minutes 4.seconds)
            expect(input.to_rounded_s).to eq('2 hours, 3 minutes')
          end

          it 'not adjacent' do
            input = (1.month 3.hours 5.seconds)
            expect(input.to_rounded_s).to eq('1 month, 3 hours')
          end
          end # describe 'not subject to rounding and'

          describe 'subject to rounding due to' do
            it 'the third unit being rounded up' do
              input = (3.days 4.hours 31.minutes)
              expect(input.to_rounded_s).to eq('3 days, 5 hours')
            end
          end # describe 'subject to rounding due to'
      end # describe 'more than two units specified that are'
    end # describe 'by default, rounds to two units when'
  end # describe '#to_rounded_s'
end
