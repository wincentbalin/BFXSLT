<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- Stylesheet for processing of the Brainfuck XML documents -->

<!-- Here are the pragmas -->
<xsl:output method="text" encoding="ISO-8859-1"/>

<!-- Parameters -->
<!-- Debug or not -->
<xsl:param name="debug" select="'no'"/>
<!-- Data length, usually 30000 -->
<xsl:param name="data-length" select="30000"/>

<!-- Variables -->
<!-- Code -->
<xsl:variable name="code">
	<xsl:value-of select="translate(normalize-space(//Brainfuck/Code), ' ', '')"/>
</xsl:variable>
<xsl:variable name="code-length" select="string-length($code)"/>
<!-- Data memory -->
<xsl:variable name="data">
	<xsl:call-template name="fill-data"/>
</xsl:variable>
<!-- Input -->
<xsl:variable name="input" select="//Brainfuck/Input"/>
<xsl:variable name="input-length" select="string-length($input)"/>
<!-- Jump table -->
<xsl:variable name="jump-table">
	<xsl:call-template name="fill-jumps"/>
</xsl:variable>

<!-- Auxilary functions -->

<!-- Fills the data list with zeroed elements -->
<xsl:template name="fill-data">
	<xsl:param name="position" select="$data-length"/>

	<xsl:if test="$position != 0">
		<element>0</element>
		<xsl:call-template name="fill-data">
			<xsl:with-param name="position" select="$position - 1"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<!-- Fills the jump table with jump pairs -->
<xsl:template name="process-jumps">
	
</xsl:template>
<!-- Processes the code -->
<xsl:template name="process-code">
	<xsl:param name="data-memory" select="$data"/>
	<xsl:param name="code-pointer" select="0"/>
	<xsl:param name="data-pointer" select="0"/>
	<xsl:param name="input-pointer" select="0"/>


</xsl:template>

<!-- Main function -->
<xsl:template match="//Brainfuck">
	<xsl:value-of select="$code"/>
	<xsl:value-of select="string-length($data)"/>
</xsl:template>

</xsl:transform>
