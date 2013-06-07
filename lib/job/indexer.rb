require 'resque'

class Indexer
  attr_accessor :endpoint

  @queue = :citi_indexing

  def work

  end
end