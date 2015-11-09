class Raconteur
  DEFAULTS = {
    processors: [],
    settings: {
      closing_tag: 'end',
      setting_quotes: '"'
    }
  }
  ORIGINAL_DEFAULTS = Marshal.load(Marshal.dump(DEFAULTS)).freeze
  ATTRS = DEFAULTS.keys.freeze

  # Bootstrap attributes
  def initialize(customizations={})
    @data = Marshal.load(Marshal.dump(DEFAULTS))
    @raconteur = self
  end

  # Parse the inputted text with the registered processors
  def parse(text="", scope=nil)
    Raconteur::Parse.scoped self, text, scope
  end

  # Prettier print
  def inspect
    "#<Raconteur:0x#{object_id} #{ATTRS.map { |att| "@#{att}=#{send(att).inspect}" }.join(', ')}>"
  end

  # Accessing settings and processors
  def settings
    Raconteur::Setting.scoped self
  end
  def processors
    Raconteur::Processor.scoped self
  end


  private

  def data
    @data
  end

end

require "raconteur/version"
require "raconteur/config"
require "raconteur/processor"
require "raconteur/setting"
require "raconteur/parse"
