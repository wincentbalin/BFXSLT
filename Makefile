#
# Runs example script
#

JAVA = java
JAVA_OPTS = -Xmx2048m -jar 

SAXON_JAR = /usr/share/saxon-bin/lib/saxon8.jar
SAXON_OPTS = -novw
#SAXON_OPTS = -novw -t
#SAXON_OPTS = 

XALAN_JAR = /usr/share/xalan/lib/xalan.jar
XALAN_OPTS = 

STYLESHEET = bf.xsl
TESTFILE = bf-helloworld.xml

all: saxon

doc:
	docbook2pdf bf-doc.xml

saxon:
	$(JAVA) $(JAVA_OPTS) $(SAXON_JAR) $(SAXON_OPTS) $(TESTFILE) $(STYLESHEET)

xalan:
	$(JAVA) $(JAVA_OPTS) $(XALAN_JAR) $(XALAN_OPTS) -IN $(TESTFILE) -XSL $(STYLESHEET)

libxslt:
	xsltproc $(STYLESHEET) $(TESTFILE)

clean:
	rm -f bf-doc.pdf

