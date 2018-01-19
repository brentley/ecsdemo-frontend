require 'net/http'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Example endpoint that calls the backend nodejs api
  def index
    begin
      url = URI.parse(backend_addr)
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }

      if res.code == '200'
        @text = res.body
      else
        @text = "no backend found"
      end

      crystalurl = URI.parse(crystal_addr)
      crystalreq = Net::HTTP::Get.new(crystalurl.to_s)
      crystalres = Net::HTTP.start(crystalurl.host, crystalurl.port) {|http|
        http.request(crystalreq)
      }

      if crystalres.code == '200'
        @crystal = crystalres.body
      else
        @crystal = "no backend found"
      end

    rescue
      @text = "no backend found"
      @crystal = "no backend found"
    end
  end

  # This endpoint is used for health checks. It should return a 200 OK when the app is up and ready to serve requests.
  def health
    render plain: "OK"
  end

  def crystal_addr
    crystal_addr = ENV["BACKEND_API"]
    # The address will be of the form, http://172.17.0.5:5432, so we add a trailing slash
    crystal_addr.sub(/^http:/, 'http:') + "/crystal"
  end

  def backend_addr
    backend_addr = ENV["BACKEND_API"]
    # The address will be of the form, http://172.17.0.5:5432, so we add a trailing slash
    backend_addr.sub(/^http:/, 'http:') + "/"
  end

  before_action :discover_availability_zone
  before_action :code_hash

  def discover_availability_zone
    @az = ENV["AZ"]
  end

  def code_hash
    @code_hash = ENV["CODE_HASH"]
  end

  def custom_header
    response.headers['Cache-Control'] = 'max-age=86400, public'
  end
end
