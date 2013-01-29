require "digest/sha2"

# TODO : add a salt for security reasons

class Admin::AgencyUser < ActiveRecord::Base
  has_many :addresses, :as => :addressable

  attr_accessible :email, :firstname, :lastname, :password, :rights

  attr_accessor :password

  before_save :encrypt_password

  validates_length_of :password, :within => 5..40, :message => "Length of the password must be within 5 and 40 characters"
  validates_presence_of :email, :message => "Email is required"
  validates_presence_of :password, :on => :create, :message => "Password is required"
  validates_uniqueness_of :email, :message => "Email already exists in the application"
  validates_confirmation_of :password, :message => "Password confirmation is wrong"
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid email"

  # encrypt a
  def self.encrypt(input)
    Digest::SHA2.hexdigest(input)
  end

  def encrypt_password()
    if password.present?
      password = Admin::AgencyUser.encrypt(password)
    end
  end
end
