<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- Stylesheet for processing of the Brainfuck XML documents -->

<!-- Here are the pragmas -->
<xsl:output method="text"/>

<!-- Parameters -->
<!-- Debug or not -->
<xsl:param name="debug" select="'no'"/>
<!-- Data length, usually 30000 -->
<xsl:param name="data-length" select="30000"/>

<!-- Variables -->
<!-- Code memory -->
<xsl:variable name="code"
              select="translate(normalize-space(//Brainfuck/Code), ' ', '')"/>
<!-- Length of code -->
<xsl:variable name="code-length" select="string-length($code)"/>
<!-- Data memory -->
<xsl:variable name="data">
	<xsl:call-template name="reset-data">
		<xsl:with-param name="size" select="$data-length"/>
	</xsl:call-template>
</xsl:variable>
<!-- Input -->
<xsl:variable name="input" select="/Brainfuck/Input"/>
<!-- Length of input -->
<xsl:variable name="input-length" select="string-length($input)"/>
<!-- Jump table -->
<xsl:variable name="jump-table">
</xsl:variable>

<!-- Auxilary functions -->
<!-- Fills the data list with elements -->
<xsl:template name="reset-data">
	<xsl:param name="size"/>

	<xsl:if test="$size != 0">
		<cell>0</cell>
		<xsl:call-template name="reset-data">
			<xsl:with-param name="size" select="$size - 1"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>
<!-- Fills the jump table with jump pairs -->
<xsl:template name="process-jumps">
	
</xsl:template>
<!-- Processes the code -->
<xsl:template name="process-code">
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
