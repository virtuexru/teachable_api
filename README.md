# TeachableApi

Ruby gem that wraps the endpoints of this HTTP API [Todoable @ Teachable.tech](http://todoable.teachable.tech)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'teachable_api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install teachable_api

## Usage

```ruby
@client = TeachableApi::Client.new("username", "password")

# Get array of lists
@client.get_lists

# Get specific list by :id
@client.get_list(list_id)

# Add list(s)
@client.add_lists({:list=>{:name=>"Test List"}})

# Update existing list by :id
@client.update_lists(list_Id, {:list=>{:name=>"Ranchos Dineros"}})

# Delete a list by :id
@client.delete_list(list_id)

# Add an item to list by :id
@client.add_item(list_id, {:item=>{:name=>"Feed the cat"}})
```

## Development

Run `bundle exec rspec` to run the tests. You can also run `bundle exec irb` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/virtuexru/teachable_api.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
