class Admin::ConnectionController < ApplicationController

  before_filter :check_for_login

  def index
  end

  def login
  end

  def logout
  end

  private
  def check_for_login

  end
end
