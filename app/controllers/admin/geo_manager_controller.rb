require 'country_flag'

class Admin::GeoManagerController < ApplicationController

  include CountryFlag

  def list
    @countries = Country.all
    @country = Country.new
    @flags = CountryFlag.load
  end

  def show
  end

  def edit
  end

  def create
  end

  def index
  end
end
