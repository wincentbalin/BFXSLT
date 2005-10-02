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
		<xsl:element name="element">0</xsl:element>
		<xsl:call-template name="fill-data">
			<xsl:with-param name="position" select="$position - 1"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<!-- Fills the jump table with jump pairs -->
<xsl:template name="fill-jumps">
	<xsl:param name="position" select="0"/>

	<xsl:if test="starts-with(substring($code, $position, 1), '[')">
		<xsl:call-template name="search-correspondant">
			<xsl:with-param name="start-position" select="$position"/>
			<xsl:with-param name="opened" select="1"/>
		</xsl:call-template>
	</xsl:if>

	<xsl:if test="$position &lt; $code-length">
		<xsl:call-template name="fill-jumps">
			<xsl:with-param name="position" select="$position + 1"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<!-- Searches for the corresponding closing bracket -->
<xsl:template name="search-correspondant">
	<xsl:param name="start-position"/>
	<xsl:param name="position" select="$start-position + 1"/>
	<xsl:param name="opened"/>

	<xsl:variable name="changed-opened">
		<xsl:call-template name="change-opened">
			<xsl:with-param name="opened" select="$opened"/>
			<xsl:with-param name="instruction" select="substring($code, $position, 1)"/>
		</xsl:call-template>
	</xsl:variable>

	<xsl:choose>
		<xsl:when test="$changed-opened = 0">
			<xsl:element name="element">
				<xsl:attribute name="from">
					<xsl:value-of select="$start-position"/>
				</xsl:attribute>
				<xsl:attribute name="to">
					<xsl:value-of select="$position"/>
				</xsl:attribute>
			</xsl:element>
		</xsl:when>
		<xsl:otherwise>
			<xsl:if test="$position &lt; $code-length">
				<xsl:call-template name="search-correspondant">
					<xsl:with-param name="start-position" select="$start-position"/>
					<xsl:with-param name="position" select="$position + 1"/>
					<xsl:with-param name="opened" select="$changed-opened"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Increases or decreases level of opened brackets -->
<xsl:template name="change-opened">
	<xsl:param name="opened"/>
	<xsl:param name="instruction"/>

	<xsl:choose>
		<xsl:when test="$instruction = '['">
			<xsl:value-of select="$opened + 1"/>
		</xsl:when>
		<xsl:when test="$instruction = ']'">
			<xsl:value-of select="$opened - 1"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$opened"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Increases code pointer dependant of the current command,
     because some commands jump -->
<xsl:template name="next-instruction">
	<xsl:param name="code-pointer"/>
	<xsl:param name="data-pointer"/>
	<xsl:param name="data"/>
	<xsl:param name="command"/>

	<xsl:choose>
		<xsl:when test="starts-with($command, '[')">
			<xsl:choose>
				<xsl:when test="$data/element[position()-1 = $data-pointer] = 0">
					<xsl:value-of select="$jump-table/element[@from = $code-pointer]/@to + 1"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$code-pointer + 1"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
		<xsl:when test="starts-with($command, ']')">
			<xsl:choose>
				<xsl:when test="$data/element[position()-1 = $data-pointer] != 0">
					<xsl:value-of select="$jump-table/element[@to = $code-pointer]/@from"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$code-pointer + 1"/>
				</xsl:otherwise>
			</xsl:choose>
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
		<xsl:call-template name="ascii2char">
			<xsl:with-param name="ascii" select="$data/element[position()-1 = $data-pointer]"/>
		</xsl:call-template>
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

	<xsl:choose>
		<xsl:when test="starts-with($command, '+')">
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
		<xsl:when test="starts-with($command, '-')">
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
		<xsl:when test="starts-with($command, ',')">
			<xsl:call-template name="char2ascii">
				<xsl:with-param name="char" select="substring($input, $input-pointer, 1)"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$data/element[position()-1 = $data-pointer]"/>
		</xsl:otherwise>
	</xsl:choose>

	<xsl:copy-of select="$data/element[position()-1 &gt; $data-pointer]"/>
</xsl:template>

<!-- Converts a 1-character string to it's ASCII code -->
<xsl:template name="char2ascii">
	<xsl:param name="char"/>

	<xsl:choose>
		<xsl:when test="$char = ' '">32</xsl:when>
		<xsl:when test="$char = '!'">33</xsl:when>
		<xsl:when test="$char = '@'">64</xsl:when>
		<xsl:when test="$char = 'A'">65</xsl:when>
		<xsl:otherwise>32</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Converts a number of ASCII code to character -->
<xsl:template name="ascii2char">
	<xsl:param name="ascii"/>

	<xsl:choose>
		<xsl:when test="$ascii = 10">
			<xsl:text disable-output-escaping="yes">
</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 32">
			<xsl:text disable-output-escaping="yes"> </xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 33">
			<xsl:text disable-output-escaping="yes">!</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 64">
			<xsl:text disable-output-escaping="yes">@</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 65">
			<xsl:text disable-output-escaping="yes">A</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 72">
			<xsl:text disable-output-escaping="yes">H</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 87">
			<xsl:text disable-output-escaping="yes">W</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 100">
			<xsl:text disable-output-escaping="yes">d</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 101">
			<xsl:text disable-output-escaping="yes">e</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 108">
			<xsl:text disable-output-escaping="yes">l</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 111">
			<xsl:text disable-output-escaping="yes">o</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 114">
			<xsl:text disable-output-escaping="yes">r</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 119">
			<xsl:text disable-output-escaping="yes">w</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$ascii"/>
<!--			<xsl:text disable-output-escaping="yes">x</xsl:text> -->
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Main function      -->
<!-- Processes the code -->
<xsl:template name="process-code" match="//Brainfuck">
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
Data: <xsl:value-of select="$data-memory"/>
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
			<xsl:with-param name="data-pointer" select="$data-pointer"/>
			<xsl:with-param name="data" select="$changed-data"/>
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

</xsl:transform>
