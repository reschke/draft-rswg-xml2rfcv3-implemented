# XSLT processor of choice
XSLT=saxon -now:$(shell date -r $< -u +%Y-%m-%dT%H:%M:%SZ)

VERSION=01

all: \
	draft-irse-xml2rfcv3-implemented.redxml \
	draft-irse-xml2rfcv3-implemented.txt \
	xml2rfcv3-annotated.rng

ship:	draft-irse-xml2rfcv3-implemented.redxml
	rm -f draft-irse-xml2rfcv3-implemented-*.xml
	ln -sf draft-irse-xml2rfcv3-implemented.redxml draft-irse-xml2rfcv3-implemented-${VERSION}.xml

#	draft-irse-xml2rfcv3-implemented.unpg.txt \

allhtml: \
	draft-irse-xml2rfcv3-implemented-${VERSION}.redxml \
	xml2rfcv3-annotated.rng \
	draft-irse-xml2rfcv3-implemented-${VERSION}.html

xml2rfc.all: \
	draft-irse-xml2rfcv3-implemented.xml xml2rfcv3-annotated.rng

xml2rfcv3.rnc: xml2rfcv3.rng SVG-1.2-RFC.rnc SVG-1.2-RFC.rng
	java -jar trang.jar -o lineLength=69 $< $@

#xml2rfcv3.dtd: xml2rfcv3.rng
#	java -jar trang.jar $< $@

xml2rfcv3-annotated.rng: xml2rfcv3.rng annotate-rng.xslt draft-irse-xml2rfcv3-implemented.xml
	$(XSLT) $< annotate-rng.xslt doc=draft-irse-xml2rfcv3-implemented.xml > $@

xml2rfcv3-spec.xml: xml2rfcv3.rng rng2xml2rfc.xslt
	$(XSLT) $< rng2xml2rfc.xslt voc=v3 specsrc=draft-irse-xml2rfcv3-implemented.xml > $@

xml2rfcv3-spec-deprecated.xml: xml2rfcv3.rng rng2xml2rfc.xslt
	$(XSLT) $< rng2xml2rfc.xslt voc=v3 specsrc=draft-irse-xml2rfcv3-implemented.xml deprecated=yes > $@
#	$(XSLT) $< rng2xml2rfc.xslt specsrc=draft-irse-xml2rfcv3-implemented.xml deprecated=yes > $@

xml2rfcv3.rnc.folded: xml2rfcv3.rnc
	./fold-rnc.sh $< | tr -d "\\015" > $@

draft-irse-xml2rfcv3-implemented.xml: xml2rfcv3-spec.xml xml2rfcv3-spec-deprecated.xml xml2rfcv3.rnc.folded differences-from-v2.txt
	cp -v $@ $@.bak
	./refresh-inclusions.sh $@

xml2rfcv2 = xml2rfcv2.rnc

differences-from-v2.txt:	xml2rfcv3.rnc $(xml2rfcv2)
	fold -w66 -s $(xml2rfcv2) > $@.v2
	fold -w66 -s $<  > $@.v3
	diff -w --old-line-format='- %L' --new-line-format='+ %L' \
	--unchanged-line-format='  %L' -d $@.v2 $@.v3 \
	| sed "s/\&/\&amp;/g" | tr -d "\\015" > $@
	rm -f $@.v2 $@.v3

%.redxml:	%.xml
	$(XSLT) -l $< clean-for-xml2rfc-v3.xslt > $@

%.txt:	%.redxml
	xml2rfc --v3 --text $< -o $@

%.html:	%.redxml
	xml2rfc --v3 --html $< -o $@

%.unpg.txt:	%.redxml
	xml2rfc --v3  --no-pagination $< -o $@

SVG-1.2-RFC.rnc:
	wget https://raw.githubusercontent.com/ietf-tools/xml2rfc/main/xml2rfc/data/SVG-1.2-RFC.rnc
#	wget https://svn.tools.ietf.org/svn/tools/xml2rfc/trunk/cli/xml2rfc/data/SVG-1.2-RFC.rnc

SVG-1.2-RFC.rng:
	wget https://raw.githubusercontent.com/ietf-tools/xml2rfc/main/xml2rfc/data/SVG-1.2-RFC.rng
#	wget https://svn.tools.ietf.org/svn/tools/xml2rfc/trunk/cli/xml2rfc/data/SVG-1.2-RFC.rng

clean:
	rm -f SVG-1.2-RFC.rnc SVG-1.2-RFC.rng draft-irse-xml2rfcv3-implemented.txt draft-irse-xml2rfcv3-implemented.html \
		draft-irse-xml2rfcv3-implemented.redxml draft-irse-xml2rfcv3-implemented.unpg.txt differences-from-v2.txt \
		xml2rfcv3.rnc xml2rfcv3-annotated.rng xml2rfcv3-spec.xml xml2rfcv3-spec-deprecated.xml \
		xml2rfcv3.rnc.folded *.bak
