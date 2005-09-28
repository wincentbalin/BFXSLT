#
# Runs example script
#

all: test

doc:
	docbook2pdf bf-doc.xml

test:
	saxon bf-helloworld.xml bf.xsl

clean:
	rm -f bf-doc.pdf

