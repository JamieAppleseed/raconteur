require 'test_helper'

class RaconteurConfigurationsTest < Minitest::Test
  def setup
    Raconteur::Config.revert_to_original_defaults!
    @original = Raconteur.new
  end

  def test_new_raconteurs_load_with_default_settings
    assert_equal @original.settings.all, Raconteur::Config.default_settings
  end

  def test_manipulating_default_settings
    Raconteur::Config.closing_tag = 'close'
    assert Raconteur.new.settings.all != @original.settings.all
  end

  def test_manipulating_and_reverting_default_settings
    original_defaults = Raconteur::Config.default_settings.dup
    Raconteur::Config.closing_tag = 'close'
    changed_defaults = Raconteur::Config.default_settings.dup
    Raconteur::Config.revert_to_original_defaults!
    reverted_defaults = Raconteur::Config.default_settings.dup

    assert original_defaults != changed_defaults
    assert_equal original_defaults, reverted_defaults
  end

  def test_preservation_of_original_defaults
    original_defaults = Raconteur::Config.default_settings.dup
    Raconteur::Config.closing_tag = 'close'

    assert Raconteur::Config.default_settings != Raconteur::Config.original_default_settings
    assert_equal original_defaults, Raconteur::Config.original_default_settings
  end

end
