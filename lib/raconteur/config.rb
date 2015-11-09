class Raconteur::Config

  # return current default settings for Raconteur
  def self.default_settings
    Raconteur::DEFAULTS[:settings]
  end
  # revert default settings for Raconteur to original defaults
  def self.revert_to_original_defaults!
    Raconteur::DEFAULTS[:settings] = original_default_settings
  end
  # return a copy of the original default settings
  def self.original_default_settings
    Marshal.load(Marshal.dump(Raconteur::ORIGINAL_DEFAULTS[:settings]))
  end
  # Let user override defaults for Raconteur
  class << self
    Raconteur::Config.default_settings.keys.each do |att|
      define_method(att) do
        self.default_settings[att]
      end
      define_method("#{att}=") do |val|
        self.default_settings[att] = val
      end
    end
  end

end
