module TeachableApi
  class Client
    include HTTParty

    attr_accessor :token, :lists, :list

    base_uri "http://todoable.teachable.tech/api"
    format :json

    ##
    # INIT
    ##
    def initialize(username = nil, password = nil)
      perform_authorization(username, password)
      self.class.default_options.merge!(headers: { 'Authorization' => "Token token=\"#{@token}\"" }) if @token
    end

    ##
    # CALLS
    ##
    def get_lists
      get_call = parse_response(self.class.get("/lists"))
      @lists = get_call unless @lists == get_call
      @lists
    end

    def get_list(id)
      get_call = parse_response(self.class.get("/lists/#{id}"))
      @list = get_call unless @list == get_call
      @list
    end

    def add_list(data)
      parse_response(self.class.post("/lists", parse_data(data)))
    end

    def update_lists(list_id, data)
      self.class.patch("/lists/#{list_id}", parse_data(data)).body
    end

    def delete_list(id)
      parse_response(self.class.delete("/lists/#{id}"))
    end

    def add_item(list_id, data)
      parse_response(self.class.post("/lists/#{list_id}/items", parse_data(data)))
    end

    def finish(list_id, item_id)
      self.class.put("/lists/#{list_id}/items/#{item_id}/finish").body
    end

    def delete_item(list_id, item_id)
      parse_response(self.class.delete("/lists/#{list_id}/items/#{item_id}"))
    end

    private

    ##
    # HELPER METHODS
    ##
    def parse_data(data)
      { body: data.to_json }
    end

    def parse_response(response)
      case response.code
      when 200
        JSON.parse(response.body)
      when 201
        JSON.parse(response.body)
      when 204
        "Object deleted"
      when 404
        "Object not found"
      when 422
        "Error(s): #{response}"
      else
        raise "Unknown error, response object: #{response.inspect}"
      end
    end

    def perform_authorization(username, password)
      raise "Please provide a username or password" if username.nil? || password.nil?

      response = self.class.post(
        '/authenticate',
        basic_auth: { username: username, password: password }
      )

      @token = response["token"]
      return self
    rescue => e
      raise e
    end
  end
end
