class Raconteur::Processor
  DEFAULTS = {
    tag: nil,
    template: nil,
    handler: nil,
    settings: {}
  }.freeze
  ATTRS = DEFAULTS.keys.freeze

  # register new processor by providing a tag name + any settings (optional)
  def self.register!(tag, customizations={})
    if find(tag)
      raise 'Processor already exists!'
    else
      all << Raconteur::Processor.new(tag, customizations)
    end
    self
  end

  # delete existing processor by tag name
  def self.deregister!(tag)
    all.delete(find(tag))
    self
  end

  # update existing processor by providing its tag name and passing in any customizations (optional)
  def self.update!(tag, customizations={})
    deregister!(tag)
    register!(tag, customizations)
    self
  end

  # scoped
  def self.scoped(raconteur)
    @@raconteur = raconteur
    self
  end

  # return array of all processors
  def self.all
    @@raconteur.send(:data)[:processors]
  end

  # find processor by tag name
  def self.find(tag)
    all.detect { |processor| processor.tag == tag }
  end

  # print array
  def self.inspect
    "#{all} (Raconteur::Processor array)"
  end

  # treat class as array
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


  # -- Instances --

  # new processor
  def initialize(tag, customizations={})
    @data = Marshal.load(Marshal.dump(DEFAULTS))
    @processor = self
    @processor.tag = tag
    @processor.template = customizations[:template] if customizations[:template].is_a?(String)
    @processor.handler = customizations[:handler] if customizations[:handler].is_a?(Proc)
    @processor
  end

  # prettier print
  def inspect
    "#<Raconteur::Processor:0x#{object_id} #{ATTRS.map { |att| "@#{att}=#{@processor.send(att)}" }.join(', ')}>"
  end

  # piecemeal access and manipulation of processor attributes
  ATTRS.each do |att|
    define_method(att) do
      @data[att]
    end
    define_method("#{att}=") do |val|
      @data[att] = val
    end
  end

  # regex for matching tag and its settings
  def regex
    /^\s*#{Regexp.quote(@processor.tag)}:?(?<settings>.*?)?\s*$/im
  end

  # execute the processor
  def execute(content="", settings={})
    output = content
    if self.handler
      # if the processor has a custom handler, then pass everything to it for processing
      output = self.handler.call(settings)
      if output.is_a?(Hash) && self.template
        # if the handler returns a hash and has a template, then pass the hash as options to the template
        # (this allows for custom variable setting and overriding before the template is rendered)
        output = Raconteur::Parse.render_template(self.template, output)
      end
    elsif self.template
      # if there's no handler but there is a processor, simply render the template with the tag's settings
      output = Raconteur::Parse.render_template(self.template, settings)
    end
    output
  end

end
