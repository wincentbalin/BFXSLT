#
# Runs example script
#

SAXON_OPTS = -novw
#SAXON_OPTS = -novw -t
#SAXON_OPTS = 

STYLESHEET = bf.xsl
TESTFILE = bf-helloworld.xml

all: saxon

doc:
	docbook2pdf bf-doc.xml

saxon:
	saxon $(SAXON_OPTS) $(TESTFILE) $(STYLESHEET)

libxslt:
	xsltproc $(STYLESHEET) $(TESTFILE)

clean:
	rm -f bf-doc.pdf

