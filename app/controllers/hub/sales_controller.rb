require 'open-uri'

class Hub::SalesController < ApplicationController

  before_filter :check_for_agency_id

  respond_to :xml, :json

  def index
  end

  def create
  end

  def edit
  end

  def delete
  end

  def save
  end

  def trends
  end

  def test
    url = 'http://soapciti.self.local/rest?format=json'
    @r = JSON.parse(open(url).read)
    respond_with @r
  end
end
