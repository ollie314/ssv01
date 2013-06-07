require 'json/ext'
require 'couchrest'
require 'msgpack'
require 'eventmachine'

class CouchDao
  def initialize(uri)
    @uri = uri unless uri.nil?
    @db = CouchRest.database uri unless uri.nil?
    @initialized = !uri.nil?
  end

  def find(id)
    o = @db.get(id)
    #MessagePack.unpack o
  end

  def save(doc)
    #_doc = MessagePack.pack doc
    CouchRest.post @uri, doc
  end

  def update(doc)
    CouchRest.put @uri, doc
  end

  def delete(doc)
    @db.delete_doc doc
  end

  def find_all
    uri = "%s/_all_docs" % (@uri)
    CouchRest.get uri
  end

  def purge
    docs = find_all
    rows = docs['rows']
    rows.each { |doc|
      delete find(doc['id'])
    }
  end
end