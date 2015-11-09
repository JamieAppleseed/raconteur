class Raconteur::Setting

  # scoped
  def self.scoped(raconteur)
    @@raconteur = raconteur
    self
  end

  # return hash of all settings
  def self.all
    @@raconteur.send(:data)[:settings]
  end

  # revert the settings of this Raconteur instance to the current default settings for Raconteur
  def self.revert_to_defaults!
    self.all.delete_if { true }.merge!(Marshal.load(Marshal.dump(Raconteur::Config.default_settings)))
    self
  end

  # revert the settings of this Raconteur instance to the original default settings of Raconteur
  def self.revert_to_original_defaults!
    self.all.delete_if { true }.merge!(Marshal.load(Marshal.dump(Raconteur::Config.original_default_settings)))
    self
  end

  # piecemeal access and manipulation of settings
  Raconteur::Config.default_settings.keys.each do |att|
    define_singleton_method(att) do
      all[att]
    end
    define_singleton_method("#{att}=") do |val|
      all[att] = val
    end
  end

  # print hash
  def self.inspect
    "#{all} (Raconteur::Setting hash)"
  end

  # treat class as hash
  def self.method_missing(method_sym, *arguments, &block)
    if !arguments.empty? && block_given?
      all.send(method_sym, *arguments, &block)
    elsif !arguments.empty?
      all.send(method_sym, *arguments)
    elsif block_given?
      all.send(method_sym, &block)
    else
      all.send(method_sym)
    end
  end

end
