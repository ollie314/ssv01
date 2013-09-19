require 'json'
require 'time'
require 'test/unit'

require 'lib/citi/filter'

class TestFilter < Test::Unit::TestCase

  #
  # Json string indicate following ranges for object 2868.
  #
  #   -> occupations
  #      -> 1 : from 2013-01-01 to 2013-11-29
  #      -> 2 : from 2013-12-21 to 2013-12-28
  #   -> availability
  #      -> 1 : from 2013-11-30 to 2013-12-20
  #      -> 2 : from 2013-12-29 to 2013-12-31
  #
  def setup
    @json_string = '{"start_day_is_valid":"0","end_day_is_valid":"1","nb_of_days_occupied_for_searched_period":"14","nb_of_days_available_for_searched_period":"0","c_dispo_string_within_searched_period":"44444444444444","a_occupation":{"occupation":[{"id_object_location":"2868","start_date":"2013-01-01T00:00:00+00:00","end_date":"2013-11-29T00:00:00+00:00","searched_date_time":"2013-09-15T13:16:24+02:00","search_start_date":"2013-10-01T00:00:00+00:00","search_end_date":"2013-10-15T00:00:00+00:00"},{"id_object_location":"2868","start_date":"2013-12-21T00:00:00+00:00","end_date":"2013-12-28T00:00:00+00:00","searched_date_time":"2013-09-15T13:16:24+02:00","search_start_date":"2013-10-01T00:00:00+00:00","search_end_date":"2013-10-15T00:00:00+00:00"}]},"a_dispo":{"dispo":[{"id_object_location":"2868","start_date":"2013-11-30T00:00:00+00:00","end_date":"2013-12-20T00:00:00+00:00","searched_date_time":"2013-09-15T13:16:24+02:00","search_start_date":"2013-10-01T00:00:00+00:00","search_end_date":"2013-10-15T00:00:00+00:00"},{"id_object_location":"2868","start_date":"2013-12-29T00:00:00+00:00","end_date":"2013-12-31T00:00:00+00:00","searched_date_time":"2013-09-15T13:16:24+02:00","search_start_date":"2013-10-01T00:00:00+00:00","search_end_date":"2013-10-15T00:00:00+00:00"}]}}'
  end

  # test to ensure json_string format
  def test_read_json_string
    data_readed = JSON.parse @json_string
    assert_not_nil data_readed, "No data readed, check string and loading process"
  end

  # test to validated case when no occupation was found in the expected range
  def test_accepted_range
    start_date = '2013-11-31'
    end_date = '2013-12-10'
    filter = Filter.new start_date, end_date
    item = JSON.parse @json_string
    result = filter.accept item
    assert result, '2013-11-31 -> 2013-12-10 should be accepted'
  end

  # test to validate case when an occupations ended after the start of the expected range
  def test_not_accepted_start_not_match
    start_date = '2013-12-27'
    end_date = '2013-12-31'
    filter = Filter.new start_date, end_date
    item = JSON.parse @json_string
    result = filter.accept item
    assert !result, '2013-12-27 -> 2013-12-31 is not valid : occupation found from 2013-12-21 to 2013-12-28'
  end

  # test to validate case when an occupation start before the end of the expected range
  def test_not_accepted_end_not_match
    start_date = '2013-12-14'
    end_date = '2013-12-22'
    filter = Filter.new start_date, end_date
    item = JSON.parse @json_string
    result = filter.accept item
    assert !result, '2013-12-14 -> 2013-12-22 is not valid : occupation found from 2013-12-21 to 2013-12-28'
  end

  # test to validate case when an occupation exists in an the expected range
  def test_not_accepted_in_range_not_match
    start_date = '2013-12-26'
    end_date = '2014-01-05'
    filter = Filter.new start_date, end_date
    item = JSON.parse @json_string
    result = filter.accept item
    assert !result, '2013-12-26 -> 2014-01-05 is not valid : occupation found from 2013-12-21 to 2013-12-28'
  end

  def test_for_range_bigger_than_one_occupied
    start_date = '2013-11-28'
    end_date = '2013-12-21'
    filter = Filter.new start_date, end_date
    item = JSON.parse @json_string
    result = filter.accept item
    assert !result, '2013-12-29 -> 2014-01-05 is not valid : occupation found at least one ocuppied range between these date'
  end

  def test_for_range_bigger_than_all_occupied
    start_date = '2012-12-28'
    end_date = '2014-01-10'
    filter = Filter.new start_date, end_date
    item = JSON.parse @json_string
    result = filter.accept item
    assert !result, '2012-12-28 -> 2014-01-10 is not valid : found at least one ocuppied range between these date'
  end

end