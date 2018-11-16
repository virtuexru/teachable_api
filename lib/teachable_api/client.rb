# require "./lib/teachable_api.rb"
# client = TeachableApi::Client.new("leotest@gmail.com", "todoable")
# client.get_lists
# data = {"list": {"name": "Urgent Things"}}
# client.add_lists(data)

module TeachableApi
  class Client
    include HTTParty

    attr_accessor :token

    base_uri 'http://todoable.teachable.tech/api'

    DEFAULT_HEADERS = {
      'Accept' => "application/json",
      'Content-Type' => "application/json"
    }

    # Try: format :json instead of DEFAULT_HEADERS

    def initialize(username = nil, password = nil)
      perform_authorization(username, password)
      self.class.default_options.merge!(headers: { 'Authorization' => "Token token=\"#{@token}\"" }) if @token
    end

    def perform_authorization(username, password)
      raise "No username or password passed." if username.nil? || password.nil?

      response = self.class.post(
        '/authenticate',
        headers: DEFAULT_HEADERS,
        basic_auth: { username: username, password: password }
      )

      @token = response["token"]
      return self
    rescue => e
      raise e
    end

    def get_lists
      response = self.class.get('/lists')
      binding.pry
    end

    def add_lists(data)
      response = self.class.post('/lists', data)
      binding.pry
    end

  end
end
