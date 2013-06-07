require 'test/unit'
require_relative 'persistence.rb'

class PersistenceTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @filename = 'C:\\Users\\mehlef\\Dev\\ruby\\ssv01\\public\\cache\\11\\sales\\en_2087.json'
    @filename_2 = 'C:\\Users\\mehlef\\Dev\\ruby\\ssv01\\public\\cache\\11\\sales\\en_2088.json'
    @db_url = 'http://127.0.0.1:5984/sales_11'
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_save
    dao = CouchDao.new @db_url
    doc = JSON.parse(IO.read @filename)
    assert_not_nil doc, "Document to persist shouldn't be null"
    dao.save doc
  end

  def test_get
    skip 'Not implemented for now'
    #dao = CouchDao.new @db_url
    #doc = dao.save doc
  end

  def test_find
    dao = CouchDao.new @db_url
    docs = dao.find_all
    assert_not_nil docs, 'Some documents exists in the database'
    assert_not_nil docs['total_rows'], 'total_rows should exists in the result hash'
    assert docs['total_rows'] > 0, 'Result should contains results'
  end

  def test_purge
    dao = CouchDao.new @db_url
    dao.purge

    # test process result
    docs = dao.find_all
    assert_not_nil docs, 'Docs shouldn\'t be null'
    assert_not_nil docs['total_rows'], 'Total rows should exists in the result'
    assert_equal 0, docs['total_rows'], 'After a deletion, no rows should keep in the database'
  end
end