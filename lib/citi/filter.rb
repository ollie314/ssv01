# FIlter based on date
class Filter
  # init the date filter with start_date and end_date as string
  # include indicate if filter should consider born into the range (test should be < [resp >] or <= [resp >=])
  def initialize(start_date, end_date, include = true)
    @current_start_date = Time.parse start_date
    @current_end_date = Time.parse end_date
    @min_range_date = nil
    @max_range_date = nil
    @include = include
  end

  def accept(item)
    found_occupied_range = false
    return true if item['a_occupation'].nil? || item['a_occupation']['occupation'].nil?
    return false if item['a_dispo'].nil? || item['a_dispo']['dispo'].nil?
    if !item['a_occupation']['occupation'].class == Array
      occupations = [item['a_occupation']['occupation']]
    else
      occupations = item['a_occupation']['occupation']
    end
    occupations.each{ |_it|
      # as soon as we reach an unavailability, break out the loop and return false
      break if found_occupied_range
      start_date = Time.parse _it['start_date'].split('T')[0]
      @min_range_date = start_date if @min_range_date.nil? || start_date < @min_range_date
      end_date = Time.parse _it['end_date'].split('T')[0]
      @max_range_date = end_date if @max_range_date.nil? || end_date > @max_range_date
      found_occupied_range = check start_date, end_date
    }
    return false if found_occupied_range
    # check if an occupied exist between the expected range
    check_for_global_range
  end

  private
  def check(range_start_date, range_end_date)
    is_in_range = false
    if @include
      is_in_range = (@current_start_date >= range_start_date && @current_start_date <= range_end_date) || (@current_end_date >= range_start_date && @current_end_date <= range_end_date)
    else
      is_in_range = (@current_start_date > range_start_date && @current_start_date < range_end_date) || (@current_end_date > range_start_date && @current_end_date < range_end_date)
    end
    is_in_range
  end

  def check_for_global_range
    @current_start_date > @min_range_date && @current_end_date < @max_range_date
  end
end