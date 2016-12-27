require 'test_helper'

class RaconteurProcessorsTest < Minitest::Test
  def setup
    Raconteur::Config.revert_to_original_defaults!
    @original = Raconteur.new
  end

  def test_registering_of_processors
    assert_equal @original.processors.all, []
    @original.processors.register!("image")
    assert_equal @original.processors.size, 1
    assert_equal @original.processors.first.tag, "image"
    @original.processors.register!("page-count").register!("footnote")
    assert_equal @original.processors.map(&:tag), %w(image page-count footnote)
    assert_raises(RuntimeError) { @original.processors.register!("image") }
  end

  def test_updating_of_processors
    @original.processors.register!("image").register!("footnote")
    assert_equal @original.processors.find("image").payload, @original.processors.find("footnote").payload
    @original.processors.find("image").payload = { some_key: 'some value' }
    assert @original.processors.find("image").payload != @original.processors.find("footnote").payload
    assert_equal @original.processors.find("image").payload[:some_key], 'some value'
    @original.processors.update!("image")
    assert_equal @original.processors.find("image").payload, @original.processors.find("footnote").payload
  end

  def test_deletion_of_processors
    @original.processors.register!("image").register!("page-count").register!("footnote")
    assert_equal @original.processors.map(&:tag), %w(image page-count footnote)
    @original.processors.deregister!("page-count")
    assert_equal @original.processors.map(&:tag), %w(image footnote)
  end

  def test_processor_lookup
    @original.processors.register!("image").register!("page-count").register!("footnote")
    assert_equal @original.processors.find("page-count"), @original.processors[1]
  end

end
