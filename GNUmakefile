rst2htmlcmd = rst2html5.py

rants =
rants += index.html
rants += durable.html
rants += yaml.html

.PHONY: all
all: $(rants)

.PHONY: clean
clean:
	rm -f $(rants)

%.html: %.rst rants.css
	$(rst2htmlcmd) --stylesheet-path=rants.css --embed-stylesheet $< $@
