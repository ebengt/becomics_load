defmodule DatesTest do
  use ExUnit.Case

  test "date from day number in month" do
    day = 1

    date = Becomics_load.Dates.test_date_from_day(day)

    today = Date.utc_today()
    assert date.year === today.year
    assert date.month === today.month
    assert date.day === day
  end

  test "dates from day numbers in months" do
    start = 28
    stop = 1

    dates = Becomics_load.Dates.test_dates(start, stop)

    today = Date.utc_today()
    [first | _] = dates
    assert first.year === today.year
    assert first.month === today.month
    assert first.day === start
    next = Date.shift(today, month: 1)
    last = List.last(dates)
    assert last.year === next.year
    assert last.month === next.month
    assert last.day === stop
  end
end
