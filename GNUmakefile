SITE           = rne.srht.site

RST2HTMLFLAGS  = --stylesheet=rants.css
RST2HTMLFLAGS += --link-stylesheet
RST2HTMLFLAGS += --trim-footnote-reference-space
RST2HTMLFLAGS += --footnote-backlinks
RST2HTMLFLAGS += --footnote-references=superscript
RST2HTMLFLAGS += --rfc-references

rants =
rants += index.html
rants += durable.html
rants += rails-antipatterns.html
rants += yaml.html

.PHONY: all
all: $(rants)

.PHONY: clean
clean:
	rm -f $(rants)

%.html: %.rst
	rst2html5 --strict $(RST2HTMLFLAGS) $< $@
