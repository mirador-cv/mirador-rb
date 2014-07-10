require 'test/unit'
require 'mirador'

class MiradorTest < Test::Unit::TestCase

  dirname = File.dirname(__FILE__)

  NSFW_IM = File.join(dirname, 'images/nsfw.jpg')
  SFW_IM = File.join(dirname, 'images/sfw.jpg')

  SFW_URL = "http://demo.mirador.im/test/sfw.jpg"
  NSFW_URL = "http://demo.mirador.im/test/nsfw.jpg"

  MM = Mirador::Client.new('')

  def test_classify_files

    res = MM.classify_files([NSFW_IM, SFW_IM])

    assert_equal res.length, 2

    nsfw, sfw = res

    assert_operator nsfw.value, :>=, 0.50
    assert_operator sfw.value, :<, 0.50

    assert nsfw.name.eql?(NSFW_IM), "nsfw name does not match"
    assert sfw.name.eql?(SFW_IM), "sfw name does not match"

    assert sfw.safe
    assert (not nsfw.safe)

  end

  def test_chunked_files
    nsfw_files = [NSFW_IM]*10
    sfw_files = [SFW_IM]*10

    nres = MM.classify_files(nsfw_files)
    assert_equal nres.length, 10

    nres.each do |r|
      assert_operator r.value, :>=, 0.50
      assert r.name.eql?(NSFW_IM)
      assert (not r.safe)
    end

    sres = MM.classify_files(sfw_files)
    assert_equal sres.length, 10

    sres.each do |r|
      assert_operator r.value, :<, 0.50
      assert r.name.eql?(SFW_IM)
      assert r.safe
    end
  end

  def test_chunked_urls
    nsfw_urls = [NSFW_URL]*10
    sfw_urls = [SFW_URL]*10

    nres = MM.classify_urls(nsfw_urls)
    assert_equal nres.length, 10

    nres.each do |r|
      assert_not_nil r
      assert_operator r.value, :>=, 0.50
      assert r.name.eql?(NSFW_URL)
      assert (not r.safe)
    end

    sres = MM.classify_urls(sfw_urls)
    assert_equal sres.length, 10

    sres.each do |r|
      assert_not_nil r
      assert_not_nil r.value
      assert_operator r.value, :<, 0.50
      assert r.name.eql?(SFW_URL)
      assert r.safe
    end

  end

  def test_classify_urls
    res = MM.classify_urls([NSFW_URL, SFW_URL])

    assert_equal res.length, 2
    nsfw, sfw = res

    assert nsfw.name.eql?(NSFW_URL)
    assert sfw.name.eql?(SFW_URL)

    assert_operator nsfw.value, :>=, 0.50
    assert_operator sfw.value, :<, 0.50

    assert sfw.safe
    assert (not nsfw.safe)
  end

  def test_classify_raw
    nsfw_d, sfw_d = [NSFW_IM, SFW_IM].map { |f| File.read(f) }
    res = MM.classify_raw_images({ "nsfw" => nsfw_d, "sfw" => sfw_d })

    assert_equal res.length, 2
    nsfw, sfw = res

    assert nsfw.name.eql?('nsfw'), "invalid name: #{ nsfw.name }"
    assert sfw.name.eql?('sfw')

    assert_operator nsfw.value, :>=, 0.50
    assert_operator sfw.value, :<, 0.50

    assert sfw.safe
    assert (not nsfw.safe)
  end

end
