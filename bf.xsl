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

<!-- Increases code pointer dependant of the current command,
     because some command are &lt; and &lt; -->
<xsl:template name="next-instruction">
	<xsl:param name="code-pointer"/>
	<xsl:param name="command"/>

	<xsl:choose>
		<xsl:when test="starts-with($command, '&lt;')">
			<xsl:value-of select="$code-pointer + 2"/>
		</xsl:when>
		<xsl:when test="starts-with($command, '&gt;')">
			<xsl:value-of select="$code-pointer + 2"/>
		</xsl:when>
		<xsl:when test="starts-with($command, '[')">
			<xsl:value-of select="$code-pointer + 1"/>
		</xsl:when>
		<xsl:when test="starts-with($command, ']')">
			<xsl:value-of select="$code-pointer + 1"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$code-pointer + 1"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Moves data pointer -->
<xsl:template name="change-data-pointer">
	<xsl:param name="data-pointer"/>
	<xsl:param name="code-pointer"/>
	<xsl:param name="command"/>

	<xsl:choose>
		<xsl:when test="starts-with($command, '&lt;')">
			<xsl:if test="$data-pointer = 0">
				<xsl:message terminate="yes">Data pointer underrun on <xsl:value-of select="$data-pointer"/> at code character <xsl:value-of select="$command"/> on <xsl:value-of select="$code-pointer"/></xsl:message>
			</xsl:if>
			<xsl:value-of select="$data-pointer - 1"/>
		</xsl:when>
		<xsl:when test="starts-with($command, '&gt;')">
			<xsl:if test="$data-pointer = ($data-length - 1)">
				<xsl:message terminate="yes">Data pointer overrun on <xsl:value-of select="$data-pointer"/> at code character <xsl:value-of select="$command"/> on <xsl:value-of select="$code-pointer"/></xsl:message>
			</xsl:if>
			<xsl:value-of select="$data-pointer + 1"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$data-pointer"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Moves input pointer -->
<xsl:template name="change-input-pointer">
	<xsl:param name="input-pointer"/>
	<xsl:param name="command"/>

	<xsl:choose>
		<xsl:when test="starts-with($command, ',')">
			<xsl:value-of select="$input-pointer + 1"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$input-pointer"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Outputs a character -->
<xsl:template name="output-data">
	<xsl:param name="data"/>
	<xsl:param name="data-pointer"/>
	<xsl:param name="command"/>

	<xsl:if test="$command = '.'">
		<xsl:variable name="value" select="$data/element[position()-1 = $data-pointer]"/>
		<xsl:value-of select="string($value)"/>
	</xsl:if>
</xsl:template>

<!-- Changes data -->
<xsl:template name="change-data">
	<xsl:param name="data"/>
	<xsl:param name="data-pointer"/>
	<xsl:param name="input"/>
	<xsl:param name="input-pointer"/>
	<xsl:param name="command"/>

	<xsl:copy-of select="$data/element[position()-1 &lt; $data-pointer]"/>
	<element>

	<xsl:choose>
		<xsl:when test="$command = '+'">
			<xsl:variable name="value" select="$data/element[position()-1 = $data-pointer]"/>
			<xsl:choose>
				<xsl:when test="$value = 255">
					0
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$value + 1"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
		<xsl:when test="$command = '-'">
			<xsl:variable name="value" select="$data/element[position()-1 = $data-pointer]"/>
			<xsl:choose>
				<xsl:when test="$value = 0">
					255	
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$value - 1"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
		<xsl:when test="$command = ','">
			<xsl:call-template name="char2ascii">
				<xsl:with-param name="char" select="substring($input, $input-pointer, 1)"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$data/element[position()-1 = $data-pointer]"/>
		</xsl:otherwise>
	</xsl:choose>

	</element>
	<xsl:copy-of select="$data/element[position()-1 &gt; $data-pointer]"/>
</xsl:template>

<!-- Converts a 1-character string to it's ASCII code -->
<xsl:template name="char2ascii">
	<xsl:param name="char"/>
</xsl:template>

<!-- Converts a number of ASCII code to character -->
<xsl:template name="ascii2char">
	<xsl:param name="ascii"/>
</xsl:template>

<!-- Main function      -->
<!-- Processes the code -->
<xsl:template name="process-code">
	<xsl:param name="data-memory" select="$data"/>
	<xsl:param name="code-pointer" select="0"/>
	<xsl:param name="data-pointer" select="0"/>
	<xsl:param name="input-pointer" select="0"/>


	<xsl:variable name="command" select="substring($code, $code-pointer, 2)"/>

	<!-- Debug output - begin -->
	<xsl:if test="$debug = 'yes'">
		<xsl:message>
Length of code: <xsl:value-of select="string-length($code)"/>
Code: <xsl:value-of select="$code"/>
		</xsl:message>
		<xsl:message>
Length of data: <xsl:value-of select="string-length($data)"/>
Data: <xsl:value-of select="$data"/>
		</xsl:message>
		<xsl:message>
Length of input: <xsl:value-of select="string-length($input)"/>
Input: <xsl:value-of select="$input"/>
		</xsl:message>
		<xsl:message>
Length of jump table: <xsl:value-of select="string-length($jump-table)"/>
Jump table: <xsl:value-of select="$jump-table"/>
		</xsl:message>

		<xsl:message>Current command: <xsl:value-of select="$command"/></xsl:message>
		<xsl:message>Current data pointer: <xsl:value-of select="$data-pointer"/></xsl:message>
		<xsl:message>Current code pointer: <xsl:value-of select="$code-pointer"/></xsl:message>
		<xsl:message>Current input pointer: <xsl:value-of select="$input-pointer"/></xsl:message>
	</xsl:if>
	<!-- Debug output - end -->

	<xsl:choose>
		<xsl:when test="starts-with($command, '&lt;')">
		</xsl:when>
		<xsl:when test="starts-with($command, '&gt;')">
		</xsl:when>
		<xsl:when test="starts-with($command, '+')">
		</xsl:when>
		<xsl:when test="starts-with($command, '-')">
		</xsl:when>
		<xsl:when test="starts-with($command, '.')">
		</xsl:when>
		<xsl:when test="starts-with($command, ',')">
		</xsl:when>
		<xsl:when test="starts-with($command, '[')">
		</xsl:when>
		<xsl:when test="starts-with($command, ']')">
		</xsl:when>
		<xsl:otherwise>
			<xsl:message terminate="yes">Illegal instruction at 
				<xsl:value-of select="$code-pointer"/>
			</xsl:message>
		</xsl:otherwise>
	</xsl:choose>

	<xsl:call-template name="output-data">
		<xsl:with-param name="data" select="$data-memory"/>
		<xsl:with-param name="data-pointer" select="$data-pointer"/>
		<xsl:with-param name="command" select="$command"/>
	</xsl:call-template>

	<xsl:variable name="changed-data">
		<xsl:call-template name="change-data">
			<xsl:with-param name="data" select="$data-memory"/>
			<xsl:with-param name="data-pointer" select="$data-pointer"/>
			<xsl:with-param name="input" select="$input"/>
			<xsl:with-param name="input-pointer" select="$input-pointer"/>
			<xsl:with-param name="command" select="$command"/>
		</xsl:call-template>
	</xsl:variable>

	<xsl:variable name="changed-data-pointer">
		<xsl:call-template name="change-data-pointer">
			<xsl:with-param name="data-pointer" select="$data-pointer"/>
			<xsl:with-param name="code-pointer" select="$code-pointer"/>
			<xsl:with-param name="command" select="$command"/>
		</xsl:call-template>
	</xsl:variable>

	<xsl:variable name="changed-input-pointer">
		<xsl:call-template name="change-input-pointer">
			<xsl:with-param name="input-pointer" select="$input-pointer"/>
			<xsl:with-param name="command" select="$command"/>
		</xsl:call-template>
	</xsl:variable>

	<xsl:variable name="code-pointer-next">
		<xsl:call-template name="next-instruction">
			<xsl:with-param name="code-pointer" select="$code-pointer"/>
			<xsl:with-param name="command" select="$command"/>
		</xsl:call-template>
	</xsl:variable>


	<xsl:if test="not($code-pointer-next &gt; $code-length)">
		<xsl:call-template name="process-code">
			<xsl:with-param name="data-memory" select="$changed-data"/>
			<xsl:with-param name="code-pointer" select="$code-pointer-next"/>
			<xsl:with-param name="data-pointer" select="$changed-data-pointer"/>
			<xsl:with-param name="input-pointer" select="$changed-input-pointer"/>
		</xsl:call-template>
	</xsl:if>

</xsl:template>

<!-- Main function -->
<xsl:template match="//Brainfuck">
	<xsl:call-template name="process-code"/>
</xsl:template>

</xsl:transform>
