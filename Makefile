#
# Runs example script
#

SAXON_OPTS = -novw
#SAXON_OPTS = -novw -t
#SAXON_OPTS = 

all: test

doc:
	docbook2pdf bf-doc.xml

test:
	saxon $(SAXON_OPTS) bf-helloworld.xml bf.xsl

clean:
	rm -f bf-doc.pdf

