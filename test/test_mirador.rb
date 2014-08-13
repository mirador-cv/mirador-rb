require 'test/unit'
require './lib/mirador'
require 'base64'

class CustomTestParser

  class << self

    def parse_results res_hash
      # essentially a no-op
      res_hash
    end
  end

  attr_accessor :results

  def update partials
    @results ||= []
    @results += partials
  end

  def [](x)
    return (@results ||= [])[x]
  end

end

class MiradorTest < Test::Unit::TestCase

  dirname = File.dirname(__FILE__)

  NSFW_IM = File.join(dirname, 'images/nsfw.jpg')
  SFW_IM = File.join(dirname, 'images/sfw.jpg')

  SFW_URL = "http://demo.mirador.im/test/sfw.jpg"
  NSFW_URL = "http://demo.mirador.im/test/nsfw.jpg"

  MM = Mirador::Client.new(ENV['MIRADOR_API_KEY'])

  def test_classify_files

    res = MM.classify_files([NSFW_IM, SFW_IM])
    assert_equal res.length, 2

    nsfw, sfw = res[NSFW_IM], res[SFW_IM]

    assert_operator nsfw.value, :>=, 0.50
    assert_operator sfw.value, :<, 0.50

    assert nsfw.name.eql?(NSFW_IM), "nsfw name does not match"
    assert sfw.name.eql?(SFW_IM), "sfw name does not match"

    assert nsfw.id.eql?(NSFW_IM)
    assert sfw.id.eql?(SFW_IM)

    assert sfw.safe
    assert (not nsfw.safe)

  end

  def test_classify_urls

    res = MM.classify_urls([NSFW_URL, SFW_URL])
    assert_equal 2, res.length

    nsfw, sfw = res[NSFW_URL], res[SFW_URL]

    assert_operator nsfw.value, :>=, 0.50
    assert_operator sfw.value, :<, 0.50

    assert nsfw.name.eql?(NSFW_URL), "nsfw name does not match"
    assert sfw.name.eql?(SFW_URL), "sfw name does not match"

    assert nsfw.id.eql?(NSFW_URL)
    assert sfw.id.eql?(SFW_URL)

    assert sfw.safe
    assert (not nsfw.safe)

  end

  def test_classify_chunked_urls

    r = Hash[([NSFW_URL]*10).each_with_index.map do |url, idx|
      [ "#{ idx }-im", url ]
    end]

    res = MM.classify_urls(r)

    assert_equal 10, res.length

    res.each do |id, r|
      assert_operator r.value, :>=, 0.50
    end

  end

  def test_custom_parser
    mc = Mirador::Client.new(ENV['MIRADOR_API_KEY'], parser: CustomTestParser)
    res = mc.classify_url(NSFW_URL)
    assert res.is_a?(Hash)
  end

  def test_hash_call

    res = MM.classify_urls(nsfw: NSFW_URL, sfw: SFW_URL)

    assert res[:nsfw]
    assert res[:sfw]

    nsfw = res[:nsfw]
    sfw = res[:sfw]

    assert_operator nsfw.value, :>=, 0.50
    assert_operator sfw.value, :<, 0.50

    assert nsfw.name.eql?('nsfw'), "nsfw name does not match"
    assert sfw.name.eql?('sfw'), "sfw name does not match"

    assert nsfw.id.eql?('nsfw')
    assert sfw.id.eql?('sfw')

    assert sfw.safe
    assert (not nsfw.safe)

  end

  def test_single_url

    res = MM.classify_url(nsfw: NSFW_URL)
    res1 = MM.classify_url(NSFW_URL)

    assert_equal res.value, res1.value

  end

  def test_items_call

    res = MM.classify_urls([{ id: :nsfw, data: NSFW_URL }, { id: :sfw, data: SFW_URL }])

    assert_equal res.length, 2

    assert res[:nsfw]
    assert res[:sfw]

  end

  def test_classify_buffers

    bufs = Hash[([File.read(NSFW_IM)]*3).each_with_index.map do |b, idx|
      ["#{idx}-buf", b]
    end]


    res = MM.classify_buffers(bufs)

    res1 = MM.classify_buffer(File.read(SFW_IM))

    assert_equal res.length, 3
    assert_operator res1.value, :<=, 0.50

    res.each do |r|
      assert_operator r.value, :>=, 0.5
    end
  end

  def test_data_uris
    duri = 'data:image/jpg;base64,' + Base64.encode64(File.read(NSFW_IM)).gsub(/\n/, '')

    res = MM.classify_data_uris(nsfw: duri)

    assert res[:nsfw]
    assert_operator res[:nsfw].value, :>=, 0.50
  end

  def test_encoded_string

    tdata = Hash[[SFW_IM, NSFW_IM].map do |fname|
      [fname, Base64.encode64(File.read(fname))]
    end]

    res = MM.classify_encoded_strings(tdata)

    assert res[SFW_IM]
    assert res[NSFW_IM]

    assert_operator res[NSFW_IM].value, :>=, 0.50

  end


  def test_item_error

    res = MM.classify_urls([{ id: :nsfw, data: 'invalid-url'}, { id: :sfw, data: SFW_URL }])

    assert_equal res.length, 2
    assert res[:sfw]

    assert res.any? do |r| r.failed? end

  end

end
