# Be sure to restart your server when you modify this file.

Ssv01::Application.config.session_store :cookie_store, key: '_ssv01_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Ssv01::Application.config.session_store :active_record_store

#Rack::Session::Cookie :key => 'rack.session', :domain => 'simnetsa.ch', :path => '/', :expire_after => 2592000, :secret => '233bdbd0599911e2bcfd0800200c9a66'
