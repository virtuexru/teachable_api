require 'spec_helper'

RSpec.describe TeachableApi::Client do
  context "when no username or password is passed" do
    subject { TeachableApi::Client.new() }

    it "raises an error for lack of username and password" do
      expect { subject }.to raise_error(RuntimeError)
    end
  end

  before do
    stub_request(:post, "http://todoable.teachable.tech/api/authenticate").
       with(headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization'=>'Basic dXNlcm5hbWU6cGFzc3dvcmQ=',
        'User-Agent'=>'Ruby'
         }).
    to_return(status: 200, body: "", headers: {})
  end

  let(:client) { TeachableApi::Client.new("username", "password") }

  context "private helper methods" do
    describe "#parse_data" do
      it "returns a jsonified hash ready for api call" do
        data = {:list=>{:name=>"Test List"}}

        expect(client.send(:parse_data, data)).to be_an_instance_of(Hash)
        expect(client.send(:parse_data, data)).to eq({:body=>data.to_json})
      end
    end

    describe "#parse_response" do
      it "will return the body parsed on 200" do
        response = { body: '{"lists":[{"name":"Test List Number One","src":"http://todoable.teachable.tech/api/lists/c81da1d0-9032-4cfe-8b70-eac81738c010","id":"c81da1d0-9032-4cfe-8b70-eac81738c010"}]}', code: 200 }
        response = OpenStruct.new(response)

        expect(client.send(:parse_response, response)).to eq({"lists"=>[{"name"=>"Test List Number One", "src"=>"http://todoable.teachable.tech/api/lists/c81da1d0-9032-4cfe-8b70-eac81738c010", "id"=>"c81da1d0-9032-4cfe-8b70-eac81738c010"}]})
      end

      it "will return the body parsed on 201" do
        response = { body: '{"lists":[{"name":"Test List Number One","src":"http://todoable.teachable.tech/api/lists/c81da1d0-9032-4cfe-8b70-eac81738c010","id":"c81da1d0-9032-4cfe-8b70-eac81738c010"}]}', code: 201 }
        response = OpenStruct.new(response)

        expect(client.send(:parse_response, response)).to eq({"lists"=>[{"name"=>"Test List Number One", "src"=>"http://todoable.teachable.tech/api/lists/c81da1d0-9032-4cfe-8b70-eac81738c010", "id"=>"c81da1d0-9032-4cfe-8b70-eac81738c010"}]})
      end

      it "will return object deleted on 204" do
        response = { body: "Object deleted", code: 204 }
        response = OpenStruct.new(response)

        expect(client.send(:parse_response, response)).to eq("Object deleted")
      end

      it "will return an error on 422" do
        response = { code: 422 }
        response = OpenStruct.new(response)

        expect(client.send(:parse_response, response)).to eq("Error(s): #<OpenStruct code=422>")
      end

      it "will raise on any invalid status" do
        response = { code: 500 }
        response = OpenStruct.new(response)

        expect { client.send(:parse_response, response) }.to raise_error(RuntimeError)
      end
    end
  end

  context "client functions" do
    describe "#get_lists" do
      it "returns all available lists" do
        stub_request(:get, "todoable.teachable.tech/api/lists")
          .to_return(body: '{"lists":[{"name":"Test List Number One","src":"http://todoable.teachable.tech/api/lists/c81da1d0-9032-4cfe-8b70-eac81738c010","id":"c81da1d0-9032-4cfe-8b70-eac81738c010"}]}', status: 200)

        response = client.get_lists

        expect(response).to be_an_instance_of(Hash)
        expect(response.size).to be > 0
        expect(response["lists"].first["id"]).to eq("c81da1d0-9032-4cfe-8b70-eac81738c010")
      end
    end

    describe "#get_list" do
      it "returns list by id" do
        stub_request(:get, "todoable.teachable.tech/api/lists/c81da1d0-9032-4cfe-8b70-eac81738c010")
          .to_return(body: "{\"name\":\"Test List Number One\",\"items\":[]}", status: 200)

        response = client.get_list("c81da1d0-9032-4cfe-8b70-eac81738c010")

        expect(response).to be_an_instance_of(Hash)
        expect(response.size).to be > 0
        expect(response["name"]).to eq("Test List Number One")
      end

      it "when id doesn't exist or is invalid" do
        stub_request(:get, "todoable.teachable.tech/api/lists/c81da1d0-9032-4cfe-8b70-eac81738c011")
          .to_return(body: "", status: 404)

        response = client.get_list("c81da1d0-9032-4cfe-8b70-eac81738c011")

        expect(response).to be_an_instance_of(String)
        expect(response).to eq("Object not found")
      end
    end

    describe "#add_list" do
      it "adds a list via input" do
        stub_request(:post, "todoable.teachable.tech/api/lists")
          .to_return(body: "{\"name\":\"RSpec Test List\", \"src\":\"http://todoable.teachable.tech/api/lists/fef4ca75-3780-4a61-8a8a-e62a8cf0357c\", \"id\":\"fef4ca75-3780-4a61-8a8a-e62a8cf0357c\"}", status: 201)

        list_data = {
          :list => {
            :name => "RSpec Test List"
          }
        }

        response = client.add_list(list_data)

        expect(response).to be_an_instance_of(Hash)
        expect(response.size).to be > 0
        expect(response["name"]).to eq("RSpec Test List")
      end

      it "attempts to add a list that already exists" do
        stub_request(:post, "todoable.teachable.tech/api/lists")
          .to_return(body: "{\"name\":[\"has already been taken\"]}", status: 422)

        list_data = {
          :list => {
            :name => "RSpec Test List"
          }
        }

        response = client.add_list(list_data)

        expect(response).to be_an_instance_of(String)
        expect(response).to eq("Error(s): {\"name\":[\"has already been taken\"]}")
      end
    end

    describe "#update_lists" do
      it "updates a list using list_id" do
        list_id = "c81da1d0-9032-4cfe-8b70-eac81738c010"

        stub_request(:patch, "todoable.teachable.tech/api/lists/#{list_id}")
          .to_return(body: "RSPect Test List Rename updated", status: 200)

        list_data = {
          :list => {
            :name=>"RSpec Test List Rename"
          }
        }

        response = client.update_lists(list_id, list_data)

        expect(response).to be_an_instance_of(String)
        expect(response).to eq("RSPect Test List Rename updated")
      end
    end

    describe "#delete_list" do
      it "deletes a list using id" do
        list_id = "c81da1d0-9032-4cfe-8b70-eac81738c010"

        stub_request(:delete, "todoable.teachable.tech/api/lists/#{list_id}")
          .to_return(body: "", status: 204)

        response = client.delete_list(list_id)

        expect(response).to be_an_instance_of(String)
        expect(response).to eq("Object deleted")
      end
    end

    describe "#add_item" do
      it "adds a list via input" do
        list_id = "c81da1d0-9032-4cfe-8b70-eac81738c010"

        stub_request(:post, "todoable.teachable.tech/api/lists/#{list_id}/items")
          .to_return(body: "{\"name\":\"Feed the cat\", \"finished_at\":\"nil\", \"src\":\"http://todoable.teachable.tech/api/lists/c81da1d0-9032-4cfe-8b70-eac81738c010/items/a2c9c894-68ed-4d84-ad96-16c2ae39f906\", \"id\":\"a2c9c894-68ed-4d84-ad96-16c2ae39f906\"}", status: 201)

        item_data = {
          :item => {
            :name => "Feed the cat"
          }
        }

        response = client.add_item(list_id, item_data)

        expect(response).to be_an_instance_of(Hash)
        expect(response.size).to be > 0
        expect(response["name"]).to eq("Feed the cat")
        expect(response["finished_at"]).to eq("nil")
      end
    end

    describe "#finish" do
      it "marks an item as finished" do
        list_id = "c81da1d0-9032-4cfe-8b70-eac81738c010"
        item_id = "a2c9c894-68ed-4d84-ad96-16c2ae39f906"

        stub_request(:put, "todoable.teachable.tech/api/lists/#{list_id}/items/#{item_id}/finish")
          .to_return(body: "Feed the cat finished", status: 201)

        response = client.finish(list_id, item_id)

        expect(response).to be_an_instance_of(String)
        expect(response).to eq("Feed the cat finished")
      end
    end

    describe "#delete_item" do
      it "deletes an item from a list" do
        list_id = "c81da1d0-9032-4cfe-8b70-eac81738c010"
        item_id = "142ba092-731e-4c5a-a457-c1ed355d4ede"

        stub_request(:delete, "todoable.teachable.tech/api/lists/#{list_id}/items/#{item_id}")
          .to_return(body: "", status: 204)

        response = client.delete_item(list_id, item_id)

        expect(response).to be_an_instance_of(String)
        expect(response).to eq("Object deleted")
      end
    end
  end
end
