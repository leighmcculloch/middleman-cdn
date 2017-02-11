require "httparty"
require "active_support/core_ext/string"

module Middleman
  module Cli
	  class RackspaceClient
	    def initialize(username, api_key)
	      @username = username
	      @api_key = api_key
	      @auth_data = nil
	    end

	    def invalidate(region, container, file, notification_email: nil)
	      headers = { "x-auth-token" => get_auth_token }
	      headers.merge!({ "x-purge-email" => notification_email }) if notification_email.present?
	      response = HTTParty.delete("#{get_cdn_endpoint(region)}/#{container}#{URI.escape(file)}", { :headers => headers })
	      case response.header.code
	      when "204"
	        # success
	      when "400"
	        error_message = response.headers["x-purge-failed-reason"]
	        raise "400, #{error_message}" if error_message.present?
	        raise "400, an error occurred."
	      when "403"
	        raise "403, the server refused to respond to the request. Check your credentials."
	      when "404"
	        raise "404, the requested resource could not be found."
	      else
	        error_message = response.body
	        raise "#{response.header.code}, an error occurred. #{error_message}".rstrip
	      end
	    end

	    private

	    def perform_auth
	      return if @auth_data.present?
	      response = HTTParty.post("https://identity.api.rackspacecloud.com/v2.0/tokens", {
	        :body => {
	          "auth" => {
	            "RAX-KSKEY:apiKeyCredentials" => {
	              "username" => @username,
	              "apiKey" => @api_key
	            }
	          }
	        }.to_json,
	        :headers => {
	          "Content-Type" => "application/json"
	        }
	      })
	      case response.header.code
	      when "200"
	        @auth_data = JSON.parse(response.body)
	      else
	        error_message = response.body
	        raise "#{response.header.code}, an error occurred. #{error_message}"
	      end
	    end

	    def get_auth_token
	      perform_auth
	      @auth_data["access"]["token"]["id"]
	    end

	    def get_service_endpoint(service_type, region)
        perform_auth
        access = @auth_data["access"] if @auth_data
        serviceCatalog = access["serviceCatalog"] if access
	      service = serviceCatalog.find { |service| service["type"] == service_type } if serviceCatalog
	      endpoints = service["endpoints"] if service
	      endpoint = endpoints.find { |endpoint| endpoint["region"] == region } if endpoints
	      return public_url = endpoint["publicURL"] if endpoint
	      nil
	    end

	    def get_cdn_endpoint(region)
	    	get_service_endpoint("rax:object-cdn", region)
	    end
	  end
  end
end
