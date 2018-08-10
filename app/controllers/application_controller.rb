require 'net/http'
require 'resolv'
require 'uri'

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
    expand_url ENV["CRYSTAL_URL"]
  end

  def backend_addr
    expand_url ENV["NODEJS_URL"]
  end
  
  # Resolve the SRV records for the hostname in the URL
  def expand_url(url)
    uri = URI(url)
    resolver = Resolv::DNS.new()
    srv = resolver.getresource("_#{uri.scheme}._tcp.#{uri.host}", Resolv::DNS::Resource::IN::SRV)
    uri.host = srv.target.to_s
    uri.port = srv.port.to_s
    uri.to_s
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
