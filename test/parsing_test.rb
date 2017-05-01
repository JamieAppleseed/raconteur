require 'test_helper'

class RaconteurParsingTest < Minitest::Test
  def setup
    Raconteur::Config.revert_to_original_defaults!
    @raconteur = Raconteur.new
  end

  def test_template_parsing
    @raconteur.processors.register!("definition", {
      template: '<span class="definition">{{ term }}<span class="icon">(?)</span> <span class="description">{{ text }}</span></span>'
      })
    output = @raconteur.parse("Within the world of {{ definition: term=UXD + text=\"User Experience Design (aka UXD + UED + XD) and refers to the process of \\\"enhancing\\\" user satisfaction by improving the usability, accessibility, and pleasure provided in the interaction between the user and the product.\" }}, you really have to consider the user.")
    assert_equal output, "Within the world of <span class=\"definition\">UXD<span class=\"icon\">(?)</span> <span class=\"description\">User Experience Design (aka UXD + UED + XD) and refers to the process of \"enhancing\" user satisfaction by improving the usability, accessibility, and pleasure provided in the interaction between the user and the product.</span></span>, you really have to consider the user."
  end

  def test_settings_parsing
    @raconteur.processors.register!("graphic", {
      template: '<div class="graphic"><div class="visual"><img src="{{ url }}"></div><p class="caption">{{ caption }}</p></div>'
      })
    output = @raconteur.parse("{{ graphic: caption=\"Baymard's office in Copenhagen, Denmark\" + url=\"https://maps.googleapis.com/maps/api/staticmap?center=55.672833,12.551455&zoom=15&markers=55.672833,12.551455&size=504x260&sensor=false\" }}")
    assert_equal output, "<div class=\"graphic\"><div class=\"visual\"><img src=\"https://maps.googleapis.com/maps/api/staticmap?center=55.672833,12.551455&zoom=15&markers=55.672833,12.551455&size=504x260&sensor=false\"></div><p class=\"caption\">Baymard's office in Copenhagen, Denmark</p></div>"
  end

  def test_similarly_named_processors
    @raconteur.processors.register!("company-name-with-apostrophe", {
      template: 'Amazon\'s' })
    @raconteur.processors.register!("company-name", {
      template: 'Amazon' })
    @raconteur.processors.register!("company-name-formal", {
      template: 'Amazon.com, Inc' })
    output = @raconteur.parse("{{ company-name }} is an online mass merchant. {{ company-name-with-apostrophe }} headquarters are located in Seattle, WA. Its full name of incorporation is {{ company-name-formal }}.")
    assert_equal output, "Amazon is an online mass merchant. Amazon's headquarters are located in Seattle, WA. Its full name of incorporation is Amazon.com, Inc."
  end

  def test_custom_quote_character
    @raconteur.processors.register!("definition", {
      template: '<span class="definition">{{ term }}<span class="icon">(?)</span> <span class="description">{{ text }}</span></span>'
      })
    @raconteur.settings.setting_quotes = '$'
    output = @raconteur.parse("Within the world of {{ definition: term=UXD + text=$User Experience Design (aka UXD + UED + XD) and refers to the process of enhancing user satisfaction by improving the usability, accessibility, and pleasure provided in the interaction between the user and the product.$ }}, you really have to consider the user.")
    assert_equal output, "Within the world of <span class=\"definition\">UXD<span class=\"icon\">(?)</span> <span class=\"description\">User Experience Design (aka UXD + UED + XD) and refers to the process of enhancing user satisfaction by improving the usability, accessibility, and pleasure provided in the interaction between the user and the product.</span></span>, you really have to consider the user."
  end

  def test_custom_handler_parsing
    @raconteur.processors.register!("definition", {
      handler: lambda do |settings|
        "<span class=\"definition\">#{settings[:term]}<span class=\"icon\">(?)</span> <span class=\"description\">#{settings[:text]}</span></span>"
      end
      })
    output = @raconteur.parse("Within the world of {{ definition: term=UXD + text=\"User Experience Design (aka UXD + UED + XD) and refers to the process of \\\"enhancing\\\" user satisfaction by improving the usability, accessibility, and pleasure provided in the interaction between the user and the product.\" }}, you really have to consider the user.")
    assert_equal output, "Within the world of <span class=\"definition\">UXD<span class=\"icon\">(?)</span> <span class=\"description\">User Experience Design (aka UXD + UED + XD) and refers to the process of \"enhancing\" user satisfaction by improving the usability, accessibility, and pleasure provided in the interaction between the user and the product.</span></span>, you really have to consider the user."
  end

  def test_custom_handler_settings_overriding_combined_with_template
    @raconteur.processors.register!("definition", {
      template: '<span class="definition">{{ term }}<span class="icon">(?)</span> <span class="description">{{ text }}</span></span>',
      handler: lambda do |settings|
        { term: settings[:title], text: settings[:description] }
      end
      })
    output = @raconteur.parse("Within the world of {{ definition: title=UXD + description=\"User Experience Design (aka UXD + UED + XD) and refers to the process of \\\"enhancing\\\" user satisfaction by improving the usability, accessibility, and pleasure provided in the interaction between the user and the product.\" }}, you really have to consider the user.")
    assert_equal output, "Within the world of <span class=\"definition\">UXD<span class=\"icon\">(?)</span> <span class=\"description\">User Experience Design (aka UXD + UED + XD) and refers to the process of \"enhancing\" user satisfaction by improving the usability, accessibility, and pleasure provided in the interaction between the user and the product.</span></span>, you really have to consider the user."
  end

  def test_skipping_of_unregistered_tags
    assert_equal @raconteur.parse("Sometimes users want to write {{ tags }} that are printed."), "Sometimes users want to write {{ tags }} that are printed."
  end

  def test_wrapper_template_parsing
    @raconteur.processors.register!("gallery", {
      template: "<div class=\"gallery\">{{ _yield_ }}</div>"
      })
    assert_equal @raconteur.parse("<p>Paragraph text.</p>{{% gallery %}}<img /><img /><img />{{% end %}}<p>Paragraph text.</p>"), "<p>Paragraph text.</p><div class=\"gallery\"><img /><img /><img /></div><p>Paragraph text.</p>"
  end

  def test_nested_wrappers
    @raconteur.processors.register!("sidebar", {
      template: "<div class=\"sidebar\">{{ _yield_ }}</div>"
      })
    @raconteur.processors.register!("gallery", {
      template: "<div class=\"gallery\">{{ _yield_ }}</div>"
      })
    output = @raconteur.parse("<p>Paragraph text.</p><p>More paragraph text.</p>{{% sidebar %}}<p>Sidebar text.</p>{{% gallery %}}<img /><img /><img />{{% end %}}{{% end %}}")
    assert_equal output, "<p>Paragraph text.</p><p>More paragraph text.</p><div class=\"sidebar\"><p>Sidebar text.</p><div class=\"gallery\"><img /><img /><img /></div></div>"
  end

  def test_wrappers_and_blocks_combined
    @raconteur.processors.register!("aside", {
      template: "<div class=\"aside\">{{ _yield_ }}</div>"
      })
    @raconteur.processors.register!("definition", {
      template: '<span class="definition">{{ term }}<span class="icon">(?)</span> <span class="description">{{ text }}</span></span>'
      })
    output = @raconteur.parse("<p>Paragraph text.</p><p>More paragraph text.</p>{{% aside %}}Within the world of {{ definition: term=UXD + text=\"User Experience Design (aka UXD + UED + XD) and refers to the process of \\\"enhancing\\\" user satisfaction by improving the usability, accessibility, and pleasure provided in the interaction between the user and the product.\" }}, you really have to consider the user.{{% end %}}<p>Back to paragraph text.</p>")
    assert_equal output, "<p>Paragraph text.</p><p>More paragraph text.</p><div class=\"aside\">Within the world of <span class=\"definition\">UXD<span class=\"icon\">(?)</span> <span class=\"description\">User Experience Design (aka UXD + UED + XD) and refers to the process of \"enhancing\" user satisfaction by improving the usability, accessibility, and pleasure provided in the interaction between the user and the product.</span></span>, you really have to consider the user.</div><p>Back to paragraph text.</p>"
  end

  def test_scoped_wrapper_settings
    @raconteur.processors.register!("wrapper", template: "<div class=\"wrapper\">{{ _yield_ }}</div>")
    @raconteur.processors.register!("page-count", {
      template: 'Page {{ page }}',
      handler: lambda do |settings|
        { page: (settings[:_scope_] && settings[:_scope_][:settings] && settings[:_scope_][:settings][:page]) || '32' }
      end
      })
    assert_equal @raconteur.parse("Unwrapped line, on {{ page-count }}. {{% wrapper: page=143 %}} Wrapper lined, on {{ page-count }}. {{% wrapper: page=578 %}} Nested wrapped line, on {{ page-count }}. {{% end %}} Wrapper lined 1st level again, on {{ page-count }}. {{% end %}} Unwrapped again, on {{ page-count }}."), "Unwrapped line, on Page 32. <div class=\"wrapper\"> Wrapper lined, on Page 143. <div class=\"wrapper\"> Nested wrapped line, on Page 578. </div> Wrapper lined 1st level again, on Page 143. </div> Unwrapped again, on Page 32."
  end

  def test_alternate_closing_tag
    @raconteur.processors.register!("gallery", {
      template: "<div class=\"gallery\">{{ _yield_ }}</div>"
      })
    @raconteur.settings.closing_tag = 'close'
    output = @raconteur.parse("<p>Paragraph text.</p><p>More paragraph text.</p>{{% gallery %}}<img /><img /><img />{{% close %}}<p>Even more paragraph text.</p>")
    assert_equal output, "<p>Paragraph text.</p><p>More paragraph text.</p><div class=\"gallery\"><img /><img /><img /></div><p>Even more paragraph text.</p>"
  end

  def test_wrapper_custom_handler_parsing
    @raconteur.processors.register!("gallery", {
      handler: lambda do |settings|
        "<div class=\"gallery\">#{settings[:_yield_]}</div>"
      end
      })
    output = @raconteur.parse("<p>Paragraph text.</p><p>More paragraph text.</p>{{% gallery %}}<img /><img /><img />{{% end %}}<p>Even more paragraph text.</p>")
    assert_equal output, "<p>Paragraph text.</p><p>More paragraph text.</p><div class=\"gallery\"><img /><img /><img /></div><p>Even more paragraph text.</p>"
  end

  def test_wrapper_custom_handler_settings_overriding_combined_with_template
    @raconteur.processors.register!("aside", {
      template: '<div class="aside">{{ _yield_ }}<p class="reference-note">(Please see page {{ page_ref }} for more details.)</p></div>',
      handler: lambda do |settings|
        settings.merge({ page_ref: '43' })
      end
      })
    output = @raconteur.parse("<p>Paragraph text.</p><p>More paragraph text.</p>{{% aside %}}<p>Within the world of UXD, you really have to consider the user.</p>{{% end %}}<p>Back to paragraph text.</p>")
    assert_equal output, "<p>Paragraph text.</p><p>More paragraph text.</p><div class=\"aside\"><p>Within the world of UXD, you really have to consider the user.</p><p class=\"reference-note\">(Please see page 43 for more details.)</p></div><p>Back to paragraph text.</p>"
  end

  def test_kramdown_combination
    @raconteur.processors.register!("aside", {
      template: "<div class=\"aside\">{{ _yield_ }}<p class=\"reference-note\">(Please see page {{ page_ref }} for more details.)</p>\n\n</div>",
      handler: lambda do |settings|
        settings.merge({ page_ref: '43' })
      end
      })
    output = @raconteur.parse("Paragraph text.\n\nMore paragraph text.\n\n{{% aside %}}\n\nWithin the world of UXD, you really have to consider the user.\n\n{{% end %}}\n\nBack to paragraph text.")
    output = Kramdown::Document.new( output, { input: :GFM, parse_block_html: true } ).to_html
    output.gsub!(/\n|^\s*/mi, '') # remove line breaks and indentation for stylistic harmony with compact output version below
    assert_equal output, "<p>Paragraph text.</p><p>More paragraph text.</p><div class=\"aside\"><p>Within the world of UXD, you really have to consider the user.</p><p class=\"reference-note\">(Please see page 43 for more details.)</p></div><p>Back to paragraph text.</p>"
  end

end
