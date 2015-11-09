require 'test_helper'

class RaconteurSettingsTest < Minitest::Test
  def setup
    Raconteur::Config.revert_to_original_defaults!
    @original = Raconteur.new
  end

  def test_raconteur_instances_have_individual_settings
    @instance1 = Raconteur.new
    @instance2 = Raconteur.new
    @instance3 = Raconteur.new
    @instance2.settings.closing_tag = 'close'
    @instance3.settings.closing_tag = 'coda'

    assert_equal @instance1.settings.all, @original.settings.all
    assert_equal Raconteur::Config.default_settings, @original.settings.all
    assert @instance1.settings.all != @instance2.settings.all
    assert @instance2.settings.all != @instance3.settings.all
  end

  def test_reverting_to_default_settings
    @original.settings.closing_tag = 'close'
    assert @original.settings.all != Raconteur::Config.default_settings
    @original.settings.revert_to_defaults!
    assert_equal @original.settings.all, Raconteur::Config.default_settings
    assert_equal Raconteur::Config.default_settings, Raconteur::Config.original_default_settings
  end

  def test_reverting_to_original_default_settings
    Raconteur::Config.closing_tag = 'coda'
    @alternate = Raconteur.new
    assert @original.settings.all != @alternate.settings.all
    assert Raconteur::Config.default_settings != Raconteur::Config.original_default_settings
    @alternate.settings.revert_to_original_defaults!
    assert_equal @original.settings.all, @alternate.settings.all
    assert Raconteur::Config.default_settings != Raconteur::Config.original_default_settings
  end

end
