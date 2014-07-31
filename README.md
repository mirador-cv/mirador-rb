# Mirador

A simple Ruby client for the [mirador](http://mirador.im) Image moderation API.

## Installation

Add this line to your application's Gemfile:

    gem 'mirador'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mirador

## Usage

There are really two basic methods available on the API. To get started, you need an API key, available from [mirador.im/join](http://mirador.im/join). If you have problems with the API or this client, please contact support@mirador.im.

### `Mirador::Client.classify_files(files) -> [Mirador::Result]`

This method takes a list of filenames and returns a list of `Mirador::Result` objects. See example:

```ruby
require 'mirador'

mc = Mirador::Client.new('your_key_here')

mc.classify_files('bathing-suit.jpg', 'nsfw-user-upload.png').each do |result|
  puts "name: #{ result.name }, safe: #{ result.safe }, value: #{ result.value }"
end

```

### `Mirdor::Client.classify_urls(urls) -> [Mirador::Result]`

This method takes a list of urls and returns `Mirador::Result` objects. Identical to `classify_files`:

```ruby
require 'mirador'

mc = Mirador::Client.new('your_key_here')
mc.classify_urls('http://possibly-nsfw.com/cool.png', 'http://mysite.net/image/bad-picture.jpg').each do |result|
  puts "name: #{ result.name }, safe: #{ result.safe }, value: #{ result.value }"
end

```

### `Mirador::Result`

The `Mirador::Result` class has 3 fields:

* `Result.name` - `string`, the filename or url for this request
* `Result.safe` - `bool`, a boolean indicating whether image contains adult content.
* `Result.value` - `float`, a number 0.0 - 1.0 indicating confidence of judgement

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Support

Please submit and bugs as issues, and don't hesitate to contact support@mirador.im with questions or issues.
