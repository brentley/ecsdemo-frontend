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
      req = Net::HTTP::Get.new(nodejs_uri.to_s)
      res = Net::HTTP.start(nodejs_uri.host, nodejs_uri.port) {|http|
        http.request(req)
      }

      if res.code == '200'
        @text = res.body
      else
        @text = "no backend found"
      end

      crystalreq = Net::HTTP::Get.new(crystal_uri.to_s)
      crystalres = Net::HTTP.start(crystal_uri.host, crystal_uri.port) {|http|
        http.request(crystalreq)
      }

      if crystalres.code == '200'
        @crystal = crystalres.body
      else
        @crystal = "no backend found"
      end

    rescue => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
      @text = "no backend found"
      @crystal = "no backend found"
    end
  end

  # This endpoint is used for health checks. It should return a 200 OK when the app is up and ready to serve requests.
  def health
    render plain: "OK"
  end

  def crystal_uri
    expand_url ENV["CRYSTAL_URL"]
  end

  def nodejs_uri
    expand_url ENV["NODEJS_URL"]
  end
  
  # Resolve the SRV records for the hostname in the URL
  def expand_url(url)
    uri = URI(url)
    resolver = Resolv::DNS.new()
    srv = resolver.getresource("_#{uri.scheme}._tcp.#{uri.host}", Resolv::DNS::Resource::IN::SRV)
    uri.host = srv.target.to_s
    uri.port = srv.port.to_s
    logger.info "expanded #{url} to #{uri}"
    uri
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
