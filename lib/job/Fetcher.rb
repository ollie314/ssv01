require 'resque'

class Fetcher
  # json representation of the object
  attr_accessor :obj_stream

  @queue = :citi_loading

  def work
    return if @obj_stream.nil?
  end
end