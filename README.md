# Raconteur

With Raconteur, you can define custom text tags and have them parsed according to your specifications, allowing you to do some neat pre- and post-processing of your texts. You could for instance insert dynamic content fetched from your database whenever {{ customer-quote: id=43 }} appears in your text.

## Installation

Raconteur is a Ruby gem so install like any other gem. For example, if you're using Bundler, then add this to your application's Gemfile:

```ruby
gem 'raconteur'
```

## Usage

Raconteur is based around the notion of processors. Each processor has a tag-name and a set of instructions for how it should perform the content replacement and what it should insert.

```ruby
@raconteur = Raconteur.new
@raconteur.processors.register!('customer-quote', {
  template: '<div class="quote" id="customer-quote-{{ id }}">\'{{ text }}\' - {{ author }}</div>',
  handler: lambda do |settings|
    quote = CustomerQuote.find(settings[:id])
    { author: quote.author_name, text: quote.citation, id: quote.id }
  end
  })
@raconteur.parse("Here's what some of our customers are saying about the product:\n{{ customer-quote: id=43 }}\n{{ customer-quote: id=266 }}\n{{ customer-quote: id=7 }}")
# -- outputs --
# Here's what some of our customers are saying:
# <div class="quote" id="customer-quote-43">'The most amazing usability report I have ever read!' - James Newman</div>
# <div class="quote" id="customer-quote-266">'I cannot believe how incredible the benchmark database is!' - Jane Newton</div>
# <div class="quote" id="customer-quote-7">'Spetacular customer service.' - John Oldling</div>
```

Here's what's happening in the above example:

- We first create a new instance of Raconteur. (Tip: You can create multiple Raconteur instances, each with its own settings and set of processors.)
- We then register a processor with the tag-name 'customer-quote'. This means that any instances of {{ customer-quote }} in the parsed text will be replaced according to the settings of this processor.
- The processor has a <code>template</code> and a <code>handler</code>. The <code>template</code> is a simple string with {{ variables }} that are replaced with dynamic content. The <code>handler</code> loads the customer quotes from our database based on the id that was passed in as a setting in the customer-quote tags (i.e. {{ customer-quote: id=43 }} invokes the handler with a settings hash of { id: "43" }).
- Finally, we call the <code>parse</code> function on our Raconteur instance, which runs over the text and replaces all instances that match its registered processors according to their specifications.

Processors must always have a tag-name name along with either a template defined, a handler defined, or both. If a handler returns a hash (like in the above example), it should have a template defined as well – Raconteur will take the returned hash and use its keys as replacement variables for the template (again, like seen in the example above). Handlers may also return a string, in which Raconteur will use this as the replacement, allowing you full control over the replaced text. If there's only a template defined, Raconteur will simply pass in any inputted tag settings as variables and then replace the tag with that template.

Processors may also be used for wrapping tags, which is a great way to encapsulate sections in your text. Let's look at an example:

```ruby
@raconteur = Raconteur.new
@raconteur.processors.register!('gallery', {
  template: '<div class="aside"><p class="box-label">Aside:</p>{{ _yield_ }}</div>'
  })
@raconteur.processors.register!('image', {
  handler: lambda do |settings|
    image = MediaLibrary.find(settings[:id]).image
    "<div class=\"graphic\"><img src=\"#{image.url}\" /><p class=\"caption\">#{image.caption}</p></div>"
  end
  })
@raconteur.parse("Some paragraph text.\n\n{{ image: id=43 }}\n\nAnother paragraph.\n\n{{% aside %}}\n\nAdditional tangentially-related text.\n\n{{ image: id=125 }}\n\nWe're really getting off-topic here.\n\n{{% end %}}\n\nOk, back to regular text.")
# -- outputs --
# Some paragraph text.
#
# <div class="graphic"><img src="http://some-url.com/some-path-for-image-43.jpg" /><p class="caption">A captivating caption text for the image.</p></div>
#
# Another paragraph.
#
# <div class="aside"><p class="box-label">Aside:</p>
#
# Additional tangentially-related text.
#
# <div class="graphic"><img src="http://some-url.com/some-path-for-image-125.jpg" /><p class="caption">Another fascinating caption for another incredible image, but this time wrapped within an aside!</p></div>
#
# We're really getting off-topic here.
#
# </div>
#
# Ok, back to regular text.
```

Wrappers are registered like all other processors but are invoked a lille differently in the text by having percentage symbols added to their curly braces and needing an {{% end %}} tag to signify when they should end. Wrapper templates work the same except they have a special {{ _yield_ }} variable passed into them, which holds the contents of the wrapped content.

In the above example, you'll notice that regular tags (in this case {{ image }}) can be used within wrappers. Wrappers may also be nested within each other. Any tags (both wrappers and regular blocks) nested within a wrapper will have a special _scope_ variable passed to their <code>handler</code> method, allowing you to customize the behavior of a tag based on its surrounding context. For instance, you could register an {{ image }} tag which renders differently depending on whether it is placed within a {{% gallery %}} wrapper or not.

Let's take a look at tags:

- Tags are wrapper by two curly braces and their name should be a string without any white-space <code>{{ like-this }}</code>.
- Tags don't need any settings. Something simple like <code>{{ page-count }}</code> will work perfectly fine.
- If you do want to pass in settings to a tag, the tag-name should be followed by a colon and a set of key-value pairs. The key must not include any white-space characters and will be converted to an underscored symbol for the settings hash. The separator should be an equals '=' symbol. The value may either be a word without any white-space characters, or it can be "a text wrapped by quotes". <code>{{ definition: term=UXD + description="User Experience Design (aka UXD + UED + XD) refers to the ..." }}</code>
- To escape quotes within a quoted settings value, put a backslash in front of the quote. You may alternatively configure Raconteur to use a different symbol for wrapping the text. Both non-white-space values and quoted values may be used in the same tag (as seen in the above "User Experience Design" example where the <code>term</code> isn't quoted but the <code>description</code> is). The key-value pairs in settings don't need to be separated by anything other than a white-space character but it can greatly help readability to include some character (such as a '+' symbol, as seen in the above "User Experience Design" example).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/raconteur.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
