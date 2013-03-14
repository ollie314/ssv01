require 'uploads/fs'
require 'citi/citi_soap_loader'

class Statics::ImagesController < ApplicationController

  def sales
    agency_id = params[:agency_id]
    object_id = params[:object_id]
    filename = "#{params[:filename]}.#{params[:file_ext]}"
    file_url = Uploads::Fs.get_cache_dir.join(agency_id, 'sales', 'images', object_id).to_s + File::SEPARATOR + filename
    stream = nil
    content_type = nil
    if File.exists? file_url and File.readable? file_url
      begin
        #File.open(file_url) { |file|
        #  stream = file.read
        #}
        send_data(
            open(file_url).read,
            :filename => file_url,
            :type => "image/jpeg",
            :disposition => "inline"
        )
      rescue Exception => e
        e.message
        send_back_404
      end
    else
      send_back_404
    end
  end

  private
  def send_back_404
    filename = "404.html"
    path = Rails.root.join('public')
    stream = nil
    begin
      File.open(path.to_s + File::SEPARATOR + filename) { |file|
        stream = file.readlines
      }
      send_data(
          stream,
          :type => "text/html",
          :status => 404
      )
    rescue Exception => e
      send_data(
          '<h1>not found</h1>',
          :type => "text/html",
          :status => 404
      )
    end
  end
end
