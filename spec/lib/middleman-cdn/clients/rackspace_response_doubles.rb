require 'spec_helper'

module RackspaceResponseDoubles
  def double_for_response_auth_success
    double({
      :header => double({
        :code => "200"
      }),
      :headers => {},
      :body => {
        "access" => { "token" => { "id" => "<auth-token>" } },
        "serviceCatalog" => [
          {
            "type" => "rax:object-cdn",
            "endpoints" => [
              {
                "region" => "DFW",
                "publicURL" => "http://example.com/"
              }
            ]
          }
        ]
      }.to_json
    })
  end

  def double_for_response_auth_fail
    double({
      :header => double({
        :code => "401"
      }),
      :headers => {},
      :body => {
        "unauthorized" => {
          "code" => "401",
          "message" => "Username or api key is invalid."
        }
      }.to_json
    })
  end

  def double_for_response_delete(status_code: 204, fail_message: nil)
    d = double({
      :header => double({
        :code => "#{status_code}"
      }),
      :headers => {},
      :body => ""
    })
    if fail_message
      case status_code
      when 204, 403, 404
      when 400
        allow(d).to receive(:headers).and_return({ "x-purge-failed-reason" => fail_message })
      else
        allow(d).to receive(:body).and_return(fail_message) if status_code
      end
    end
    d
  end
end

RSpec.configure do |c|
  c.include RackspaceResponseDoubles, :include_rackspace_response_doubles
end
