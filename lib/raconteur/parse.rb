class Raconteur::Parse

  def self.scoped(raconteur, document, scope)
    @@raconteur = raconteur
    parse_blocks(parse_wrappers(document, scope), scope)
  end

  def self.parse_wrappers(document, scope)
    output = document
    regex = /{{%(.*?)%}}/m
    # scan for all instances of wrappers, i.e. {{% tag-name %}}
    wrappers = output.scan(regex).flatten
    unless wrappers.empty?
      # if wrappers, loop over all opening tags in reverse order (this way the inner-most wrapper is always processed before its parent wrappers)
      wrappers.map(&:strip).reject { |str| str == @@raconteur.settings.closing_tag }.reverse.each do |open_tag|
        # loop over each registered processor
        @@raconteur.processors.each do |processor|
          # check if the processor matches the tag
          match = open_tag.match(processor.regex)
          if match
            # if there is a match, parse the tag's settings, if it has any
            match_settings = parse_settings(match[:settings])
            # merge in the nested wrapper scope, if present
            match_settings.merge!(_scope_: scope) if scope
            # identify the tag and its contents
            regex = /.*(?<tag>{{%\s*#{Regexp.quote(open_tag)}\s*%}}(?<content>.*?){{%\s*#{Regexp.quote(@@raconteur.settings.closing_tag)}\s*%}})/m
            wrapper_match = output.match(regex)
            if wrapper_match
              # if there is a match, run its contents through raconteur with the wrapper set as scope, to perform all necessary replacements (this allows nesting and wrapper customizations)
              content = @@raconteur.parse(wrapper_match[:content], {
                tag: open_tag,
                processor: processor,
                settings: match_settings
                })
              # set _yield_ variable with the (parsed) inner contents of wrapper tag
              match_settings.merge!(_yield_: content)
              # execute processor and replace output with result
              content = processor.execute(content, match_settings)
              # replace wrapper and its contents with the parsed content
              output = output.sub(wrapper_match[:tag], content)
            end
          end
        end
      end
    end
    output
  end

  def self.parse_blocks(output, scope)
    # replace all instances of {{ some-tag }}
    output.gsub(/{{(.*?)}}/m) do |raw_str|
      # the matched string if no processing occurs
      output = raw_str
      # clean the matched string to only get the tag and its settings
      str = output.gsub(/^\{\{\%?\s*|\s*\%?\}\}$/, '')
      # loop over each registered processor
      @@raconteur.processors.each do |processor|
        # check if the processor matches the tag
        match = str.match(processor.regex)
        if match
          # parse the tag's settings, if any
          match_settings = self.parse_settings(match[:settings])
          # merge in the nested wrapper scope, if present
          match_settings.merge!(_scope_: scope) if scope
          # execute processor and replace output with result
          output = processor.execute(output, match_settings)
        end
      end
      output
    end
  end

  # input: (string) 'id=353 + report-title="E-Commerce Checkout Usability Report"'
  # output: (hash) { id: '353', report_title: 'E-Commerce Checkout Usability Report' }
  def self.parse_settings(str)
    # prepare a fresh hash for the parsed settings
    parsed_settings = {}
    # return empty hash if settings string is 'nil'
    if str == nil
      return parsed_settings
    end
    # regex escape 'quote' character
    quote = Regexp.quote(@@raconteur.settings.setting_quotes)
    # Parsing logic:
    # First, one or more non-white-space characters,
    # .. followed by an equal sign '=' character,
    # .. followed by either:
    #       a) 1+ non-white-space characters, or
    #       b) a string wrapped by the 'quote' character at both ends
    # (instances of the 'quote' character within the string can be escaped by a backward-slash '\')
    regex = /([^\s#{quote}]+)\=(#{quote}.*?[^\\]#{quote}|[^\s]+)/mi
    # loop over all key-value setting pairs in the string
    str.scan(regex).each do |setting_str|
      # grap keys and turn them into underscored symbols
      key = setting_str[0].strip.gsub('-','_').to_sym
      # strip values from whitespace and surrounding quote characters
      value = setting_str[1].strip.gsub(/^#{quote}|#{quote}$/mi, '').gsub(/\\#{quote}/mi, quote)
      # add to settings hash
      parsed_settings[key] = value
    end
    # return the parsed settings (transformed from string to hash)
    parsed_settings
  end

  def self.render_template(template, data)
    output = template
    # loop over data hash (for value substitution)
    data.each do |tag, value|
      # replace dynamic values in the template
      output = output.gsub(/{{\s*#{tag}\s*}}/, value.to_s)
    end
    output
  end

end
