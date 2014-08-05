# Mirador [![Build Status](https://drone.io/github.com/mirador-cv/mirador-rb/status.png)](https://drone.io/github.com/mirador-cv/mirador-rb/latest)

A simple Ruby client for the [mirador](http://mirador.im) Image moderation API.

## Installation

Add this line to your application's Gemfile:

    gem 'mirador'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mirador

## Usage

To get started, you need an API key, available from [mirador.im/join](http://mirador.im/). If you have problems with the API or this client, please contact support@mirador.im.

## Mirador::Result and Mirador::ResultList

All multiple-request methods (e.g., classify_files), return a [Mirador::ResultList](#resultlist), which is effectively a list of Mirador::Result objects; single-request methods (e.g., classify_url) return a [Mirador::Result](#result) object.

## Classifying Files & Buffers

You can classify 4 types of files/file-objects:

* file objects (e.g., `x` where `x = File.open('myfile.jpg')`); [classify_files](#classify_files)
* filenames `myfile.jpg` [classify_files](#classify_files)
* buffers `buffer = File.read('myfile.jpg')` [classify_buffers](#classify_buffers)
* base64-encoded buffers (e.g., from a data URI) [classify_encoded_strings](#classify_encoded_strings)

The methods for file-based classification are as follows:


### <a name="classify_files"></a> Mirador::Client#classify_files

```ruby
require 'mirador'
mc = Mirador::Client.new('your_api_key')

results = mc.classify_files('test.jpg', 'picture.jpg')

assert results['test.jpg']
assert_equal results.length, 2

results.each do |res|
  puts "#{ res.id }, #{ res.value }"
end

results.each do |id, res|
  puts "#{ id }, #{ res.value }"
end

```

You can also specify an id to be used:

```ruby
require 'mirador'
mc = Mirador::Client.new 'your_api_key'

# first method: use ids as keys
results = mc.classify_files(nsfw: 'nsfw.jpg', sfw: 'sfw.jpg')

assert results[:nsfw]
assert results[:sfw]

# second method: pass an array of { id:, data: } hashes
results = mc.classify_files([{ id: :nsfw, data: 'nsfw.jpg'}, { id: :sfw, data: 'sfw.jpg' }])

assert results[:nsfw]
assert results[:sfw]
```

File can be either a filename or a file object; e.g., the following is also valid:

```ruby
results = mc.classify_files(nsfw: File.open('nsfw.jpg'))
```

### <a name='classify_file'></a> Mirador::Client#classify_file

A shortcut for classifying a single file; this will return a `Mirador::Result` instead of a `Mirador::ResultList`:

```ruby
require 'mirador'
mc = Mirador::Client.new 'your_api_key'

# first method: use ids as keys
nsfw = mc.classify_file(nsfw: 'nsfw.jpg')

puts nsfw.value
```

### <a name='classify_buffers'></a> Mirador:Client#classify_buffers

Classify a buffer, e.g., an already-read file. This simplifies the classification of file uploads, e.g. POST data. The interface is identical to [classify_files](#classify_files), only differing in the actual data passed in:

```ruby
require 'mirador'
mc = Mirador::Client.new 'your_api_key'

nsfw_buf = File.read('nsfw.jpg')
sfw_buf = File.read('sfw.jpg')

# these are equivalent
results = mc.classify_buffers(nsfw: nsfw_buf, sfw: sfw_buf)
results = mc.classify_buffers([{id: :nsfw, data: nsfw_buf}, {id: :sfw, data: sfw_buf}])

# since buffers dont have a name, you just get an index as id
results = mc.classify_buffers(nsfw_buf, sfw_buf)
```

#### <a name='classify_buffer'></a> Mirador::Client#classify_buffer

As with classify_file, there is a shortcut for classifying only one buffer; see [classify_file](#classify_file) for clarifications on usage (it's identical).

### <a name='classify_encoded_strings'></a> Mirador::Client#classify_encoded_strings

The Mirador API internally represents images as base64-encoded strings (agnostic of image encoding); this method lets you pass in an alread-encoded string in the event that you're also using base64 encoding elsewhere in your system. Usage is the same as [classify_buffers](#classify_buffers):

```ruby
require 'mirador'
require 'base64'

mc = Mirador::Client.new 'your_api_key'

nsfw_buf = Base64.encode64(File.read('nsfw.jpg'))
sfw_buf = Base64.encode64(File.read('sfw.jpg'))

# these are equivalent
results = mc.classify_encoded_strings(nsfw: nsfw_buf, sfw: sfw_buf)
results = mc.classify_encoded_strings([{id: :nsfw, data: nsfw_buf}, {id: :sfw, data: sfw_buf}])

# since strings dont have a name, you just get an index as id
results = mc.classify_encoded_strings(nsfw_buf, sfw_buf)
```

#### <a name='classify_encoded_string'></a> Mirador::Client#classify_encoded_string

Another helper for only working with 1 request/result at a time. See [classify_file](#classify_file) for more info.


### <a name='classify_data_uris'></a> Mirador::Client#classify_data_uris

This simplifies data transfer between client applications and the mirador API. For example, given the following javascript:

```javascript
document.getElementById('form-field').addEventListener('change', function (e) {

  var file = this.files[0];

  var reader = new FileReader();
  reader.onload = function (e) {
    $.post('/proxy/mirador', { id: file.name, data: e.target.result });
  }

  reader.readAsDataURL(file);
});
```

Your could classify that data url with the following code:

```ruby

res = mc.classify_data_uris(request['id'] => request['data'])

# send the result
res[request['id']].to_json

# or, even easier
mc.classify_data_uri(request['id'] => request['data']).to_json

```

Otherwise, classify_data_uris and classify_data_uri have identical interfaces to the other methods covered so far.


## Classify URLs

You can easily classify a publically-available URL (e.g., a public s3 bucket), with [classify_urls](#classify_urls) and [classify_url](#classify_url). The interfaces for these methods are identical to the file-handling methods covered above.


### <a name='classify_urls'></a> Mirador::Client#classify_urls

The only things to keep in mind with URLs:

* must be publically-accessibly
* must be < Mirador::Client::MAX_ID_LEN if you are using the url as the item's id (see below)
* download/response time on url will affect response time of result, must be less than 60 seconds.


#### Examples:


Assigning specific ids to urls:

```ruby
require 'mirador'

mc = Mirador::Client.new 'your_api_key'

res = mc.classify_urls(nsfw: 'http://static.mirador.im/test/nsfw.jpg', sfw: 'http://static.mirador.im/test/sfw.jpg')

assert res[:nsfw]
assert res[:sfw].safe

```

Implicitly using url as its own id:

```ruby
require 'mirador'

nsfw_url = 'http://static.mirador.im/test/nsfw.jpg'
sfw_url = 'http://static.mirador.im/test/sfw.jpg'

mc = Mirador::Client.new 'your_api_key'
res = mc.classify_urls(nsfw_url, sfw_url)

puts res[nsfw_url].value
puts res[sfw_url].value
```

Classify a single URL using Mirador::Client#classify_url

```ruby
require 'mirador'

mc = Mirador::Client.new 'your_api_key'
nsfw = mc.classify_url(nsfw_url)

assert (not nsfw.safe)
puts nsfw.value
```

## <a name='result'></a> Mirador::Result

The `Mirador::Result` class wraps the output of the API for a specific image/url. It has the following attributes:

* `@id` [Mixed]: the id, as specified in the request, or implied (see above)
* `@safe` [Boolean]: whether the image should be considered flagged/containing adult content
* `@value` [Float 0.0-1.0]: A float indicating the likelyhood of the image containing adult content (useful for creating custom thresholds)
* `@error` [String]: will only be non-nil if this is an error

The `Mirador::Result` object also has a couple of convenience methods:

* `#to_h` - convert to a hash
* `#to_json` - if json is require'd, serialize to json
* `#failed?` - returns a boolean indicating whether image is a failure/error
* `#to_s` - returns a string representation of the result`
* `#name` **(deprecated)** - this simply maps to `@id`

## <a name='resultlist'></a> Mirador::ResultList [Enumerable]

Methods that return multiple results do so by returning a single `Mirador::ResultList`. This object is used in lieu of a Hash or Array as to provide mixed-access. You can treat it as an array, iterating via `each do |x|`, indexing with integers, or by simply calling `#to_a`, or as a hash, indexing with `@id`'s from image-requests.

The ResultList has the following methods:

* `#[](key)` operator override to index the ResultList. You can index by integers in range of 0 - ResultList#length, or by an `@id` for one of the Result objects within.
* `#to_a` convert to an array of `Mirador::Result` objects
* `#length` the number of items in the `ResultList`
* `#update` equivalent to Hash#update
* `#to_h` conver to a hash
* `#to_json` serialize the resultlist as json
* `#each` `ResultList` includes `Enumerable`, and this implementation of `#each` checks the arity of blocks passed in to allow iteration either as an array or as a Hash.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Support

Please submit and bugs as issues, and don't hesitate to contact support@mirador.im with questions or issues.
