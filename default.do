#!/bin/sh

case $1 in
html)
  redo-ifchange index.html durable.html rails-antipatterns.html yaml.html
;;
*.html)
  redo-ifchange ${1%.html}.rst

  exec rst2html5 \
    --strict \
    --stylesheet=rants.css,syntax.css \
    --link-stylesheet \
    --syntax-highlight=short \
    --trim-footnote-reference-space \
    --footnote-backlinks \
    --footnote-references=superscript \
    --rfc-references \
    ${1%.html}.rst \
    $3
;;
*)
  exit 1
;;
esac
