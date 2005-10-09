<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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

	<xsl:element name="element">
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
	</xsl:element>

	<xsl:copy-of select="$data/element[position()-1 &gt; $data-pointer]"/>
</xsl:template>


<!-- Main function, processes the code -->
<xsl:template name="process-code" match="//Brainfuck">
	<xsl:param name="data-memory" select="$data"/>
	<xsl:param name="code-pointer" select="0"/>
	<xsl:param name="data-pointer" select="0"/>
	<xsl:param name="input-pointer" select="0"/>


	<xsl:variable name="command" select="substring($code, $code-pointer, 1)"/>

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

		<xsl:if test="$code-pointer = 0">
			<xsl:message>
Length of jump table: <xsl:value-of select="count($jump-table/element)"/>
Jump table: <xsl:value-of select="$jump-table/*"/>
			</xsl:message>
		</xsl:if>

		<xsl:message>Current command: <xsl:value-of select="$command"/></xsl:message>
		<xsl:message>Current data pointer: <xsl:value-of select="$data-pointer"/></xsl:message>
		<xsl:message>Current code pointer: <xsl:value-of select="$code-pointer"/></xsl:message>
		<xsl:message>Current input pointer: <xsl:value-of select="$input-pointer"/></xsl:message>
	</xsl:if>
	<!-- Debug output - end -->

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


<!-- Converts a 1-character string to it's ASCII code -->
<xsl:template name="char2ascii">
	<xsl:param name="char"/>

	<xsl:choose>
		<xsl:when test="$char = '	'">9</xsl:when>
		<xsl:when test="$char = '
'">10</xsl:when>
		<xsl:when test="$char = ' '">32</xsl:when>
		<xsl:when test="$char = '!'">33</xsl:when>
		<xsl:when test="$char = '&quot;'">34</xsl:when>
		<xsl:when test="$char = '#'">35</xsl:when>
		<xsl:when test="$char = '$'">36</xsl:when>
		<xsl:when test="$char = '%'">37</xsl:when>
		<xsl:when test="$char = '&amp;'">38</xsl:when>
		<xsl:when test="$char = '('">40</xsl:when>
		<xsl:when test="$char = ')'">41</xsl:when>
		<xsl:when test="$char = '*'">42</xsl:when>
		<xsl:when test="$char = '+'">43</xsl:when>
		<xsl:when test="$char = ','">44</xsl:when>
		<xsl:when test="$char = '-'">45</xsl:when>
		<xsl:when test="$char = '.'">46</xsl:when>
		<xsl:when test="$char = '/'">47</xsl:when>
		<xsl:when test="$char = '0'">48</xsl:when>
		<xsl:when test="$char = '1'">49</xsl:when>
		<xsl:when test="$char = '2'">50</xsl:when>
		<xsl:when test="$char = '3'">51</xsl:when>
		<xsl:when test="$char = '4'">52</xsl:when>
		<xsl:when test="$char = '5'">53</xsl:when>
		<xsl:when test="$char = '6'">54</xsl:when>
		<xsl:when test="$char = '7'">55</xsl:when>
		<xsl:when test="$char = '8'">56</xsl:when>
		<xsl:when test="$char = '9'">57</xsl:when>
		<xsl:when test="$char = ':'">58</xsl:when>
		<xsl:when test="$char = ';'">59</xsl:when>
		<xsl:when test="$char = '&lt;'">60</xsl:when>
		<xsl:when test="$char = '='">61</xsl:when>
		<xsl:when test="$char = '&gt;'">62</xsl:when>
		<xsl:when test="$char = '?'">63</xsl:when>
		<xsl:when test="$char = '@'">64</xsl:when>
		<xsl:when test="$char = 'A'">65</xsl:when>
		<xsl:when test="$char = 'B'">66</xsl:when>
		<xsl:when test="$char = 'C'">67</xsl:when>
		<xsl:when test="$char = 'D'">68</xsl:when>
		<xsl:when test="$char = 'E'">69</xsl:when>
		<xsl:when test="$char = 'F'">70</xsl:when>
		<xsl:when test="$char = 'G'">71</xsl:when>
		<xsl:when test="$char = 'H'">72</xsl:when>
		<xsl:when test="$char = 'I'">73</xsl:when>
		<xsl:when test="$char = 'J'">74</xsl:when>
		<xsl:when test="$char = 'K'">75</xsl:when>
		<xsl:when test="$char = 'L'">76</xsl:when>
		<xsl:when test="$char = 'M'">77</xsl:when>
		<xsl:when test="$char = 'N'">78</xsl:when>
		<xsl:when test="$char = 'O'">79</xsl:when>
		<xsl:when test="$char = 'P'">80</xsl:when>
		<xsl:when test="$char = 'Q'">81</xsl:when>
		<xsl:when test="$char = 'R'">82</xsl:when>
		<xsl:when test="$char = 'S'">83</xsl:when>
		<xsl:when test="$char = 'T'">84</xsl:when>
		<xsl:when test="$char = 'U'">85</xsl:when>
		<xsl:when test="$char = 'V'">86</xsl:when>
		<xsl:when test="$char = 'W'">87</xsl:when>
		<xsl:when test="$char = 'X'">88</xsl:when>
		<xsl:when test="$char = 'Y'">89</xsl:when>
		<xsl:when test="$char = 'Z'">90</xsl:when>
		<xsl:when test="$char = '['">91</xsl:when>
		<xsl:when test="$char = '\'">92</xsl:when>
		<xsl:when test="$char = ']'">93</xsl:when>
		<xsl:when test="$char = '^'">94</xsl:when>
		<xsl:when test="$char = '_'">95</xsl:when>
		<xsl:when test="$char = '`'">96</xsl:when>
		<xsl:when test="$char = 'a'">97</xsl:when>
		<xsl:when test="$char = 'b'">98</xsl:when>
		<xsl:when test="$char = 'c'">99</xsl:when>
		<xsl:when test="$char = 'd'">100</xsl:when>
		<xsl:when test="$char = 'e'">101</xsl:when>
		<xsl:when test="$char = 'f'">102</xsl:when>
		<xsl:when test="$char = 'g'">103</xsl:when>
		<xsl:when test="$char = 'h'">104</xsl:when>
		<xsl:when test="$char = 'i'">105</xsl:when>
		<xsl:when test="$char = 'j'">106</xsl:when>
		<xsl:when test="$char = 'k'">107</xsl:when>
		<xsl:when test="$char = 'l'">108</xsl:when>
		<xsl:when test="$char = 'm'">109</xsl:when>
		<xsl:when test="$char = 'n'">110</xsl:when>
		<xsl:when test="$char = 'o'">111</xsl:when>
		<xsl:when test="$char = 'p'">112</xsl:when>
		<xsl:when test="$char = 'q'">113</xsl:when>
		<xsl:when test="$char = 'r'">114</xsl:when>
		<xsl:when test="$char = 's'">115</xsl:when>
		<xsl:when test="$char = 't'">116</xsl:when>
		<xsl:when test="$char = 'u'">117</xsl:when>
		<xsl:when test="$char = 'v'">118</xsl:when>
		<xsl:when test="$char = 'w'">119</xsl:when>
		<xsl:when test="$char = 'x'">120</xsl:when>
		<xsl:when test="$char = 'y'">121</xsl:when>
		<xsl:when test="$char = 'z'">122</xsl:when>
		<xsl:when test="$char = '{'">123</xsl:when>
		<xsl:when test="$char = '|'">124</xsl:when>
		<xsl:when test="$char = '}'">125</xsl:when>
		<xsl:when test="$char = '~'">126</xsl:when>
		<xsl:otherwise>32</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Converts a number of ASCII code to character -->
<xsl:template name="ascii2char">
	<xsl:param name="ascii"/>

	<xsl:choose>
		<xsl:when test="$ascii = 9">
			<xsl:text disable-output-escaping="yes">	</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 10">
			<xsl:text disable-output-escaping="yes">
</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 13">
			<xsl:text disable-output-escaping="yes">
</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 32">
			<xsl:text disable-output-escaping="yes"> </xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 33">
			<xsl:text disable-output-escaping="yes">!</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 34">
			<xsl:text disable-output-escaping="yes">"</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 35">
			<xsl:text disable-output-escaping="yes">#</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 36">
			<xsl:text disable-output-escaping="yes">$</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 37">
			<xsl:text disable-output-escaping="yes">%</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 38">
			<xsl:text disable-output-escaping="yes">&amp;</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 39">
			<xsl:text disable-output-escaping="yes">'</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 40">
			<xsl:text disable-output-escaping="yes">(</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 41">
			<xsl:text disable-output-escaping="yes">)</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 42">
			<xsl:text disable-output-escaping="yes">*</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 43">
			<xsl:text disable-output-escaping="yes">+</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 44">
			<xsl:text disable-output-escaping="yes">,</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 45">
			<xsl:text disable-output-escaping="yes">-</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 46">
			<xsl:text disable-output-escaping="yes">.</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 47">
			<xsl:text disable-output-escaping="yes">/</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 48">
			<xsl:text disable-output-escaping="yes">0</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 49">
			<xsl:text disable-output-escaping="yes">1</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 50">
			<xsl:text disable-output-escaping="yes">2</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 51">
			<xsl:text disable-output-escaping="yes">3</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 52">
			<xsl:text disable-output-escaping="yes">4</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 53">
			<xsl:text disable-output-escaping="yes">5</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 54">
			<xsl:text disable-output-escaping="yes">6</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 55">
			<xsl:text disable-output-escaping="yes">7</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 56">
			<xsl:text disable-output-escaping="yes">8</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 57">
			<xsl:text disable-output-escaping="yes">9</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 58">
			<xsl:text disable-output-escaping="yes">:</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 59">
			<xsl:text disable-output-escaping="yes">;</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 60">
			<xsl:text disable-output-escaping="yes">&lt;</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 61">
			<xsl:text disable-output-escaping="yes">=</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 62">
			<xsl:text disable-output-escaping="yes">&gt;</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 63">
			<xsl:text disable-output-escaping="yes">?</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 64">
			<xsl:text disable-output-escaping="yes">@</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 65">
			<xsl:text disable-output-escaping="yes">A</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 66">
			<xsl:text disable-output-escaping="yes">B</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 67">
			<xsl:text disable-output-escaping="yes">C</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 68">
			<xsl:text disable-output-escaping="yes">D</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 69">
			<xsl:text disable-output-escaping="yes">E</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 70">
			<xsl:text disable-output-escaping="yes">F</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 71">
			<xsl:text disable-output-escaping="yes">G</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 72">
			<xsl:text disable-output-escaping="yes">H</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 73">
			<xsl:text disable-output-escaping="yes">I</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 74">
			<xsl:text disable-output-escaping="yes">J</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 75">
			<xsl:text disable-output-escaping="yes">K</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 76">
			<xsl:text disable-output-escaping="yes">L</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 77">
			<xsl:text disable-output-escaping="yes">M</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 78">
			<xsl:text disable-output-escaping="yes">N</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 79">
			<xsl:text disable-output-escaping="yes">N</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 80">
			<xsl:text disable-output-escaping="yes">O</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 81">
			<xsl:text disable-output-escaping="yes">P</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 82">
			<xsl:text disable-output-escaping="yes">Q</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 83">
			<xsl:text disable-output-escaping="yes">R</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 84">
			<xsl:text disable-output-escaping="yes">S</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 85">
			<xsl:text disable-output-escaping="yes">T</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 86">
			<xsl:text disable-output-escaping="yes">U</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 86">
			<xsl:text disable-output-escaping="yes">V</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 87">
			<xsl:text disable-output-escaping="yes">W</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 88">
			<xsl:text disable-output-escaping="yes">X</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 89">
			<xsl:text disable-output-escaping="yes">Y</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 90">
			<xsl:text disable-output-escaping="yes">Z</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 91">
			<xsl:text disable-output-escaping="yes">[</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 92">
			<xsl:text disable-output-escaping="yes">\</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 93">
			<xsl:text disable-output-escaping="yes">]</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 94">
			<xsl:text disable-output-escaping="yes">^</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 95">
			<xsl:text disable-output-escaping="yes">_</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 96">
			<xsl:text disable-output-escaping="yes">`</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 97">
			<xsl:text disable-output-escaping="yes">a</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 98">
			<xsl:text disable-output-escaping="yes">b</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 99">
			<xsl:text disable-output-escaping="yes">c</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 100">
			<xsl:text disable-output-escaping="yes">d</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 101">
			<xsl:text disable-output-escaping="yes">e</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 102">
			<xsl:text disable-output-escaping="yes">f</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 103">
			<xsl:text disable-output-escaping="yes">g</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 104">
			<xsl:text disable-output-escaping="yes">h</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 105">
			<xsl:text disable-output-escaping="yes">i</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 106">
			<xsl:text disable-output-escaping="yes">j</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 107">
			<xsl:text disable-output-escaping="yes">k</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 108">
			<xsl:text disable-output-escaping="yes">l</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 109">
			<xsl:text disable-output-escaping="yes">m</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 110">
			<xsl:text disable-output-escaping="yes">n</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 111">
			<xsl:text disable-output-escaping="yes">o</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 112">
			<xsl:text disable-output-escaping="yes">p</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 113">
			<xsl:text disable-output-escaping="yes">q</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 114">
			<xsl:text disable-output-escaping="yes">r</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 115">
			<xsl:text disable-output-escaping="yes">s</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 116">
			<xsl:text disable-output-escaping="yes">t</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 117">
			<xsl:text disable-output-escaping="yes">u</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 118">
			<xsl:text disable-output-escaping="yes">v</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 119">
			<xsl:text disable-output-escaping="yes">w</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 120">
			<xsl:text disable-output-escaping="yes">x</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 121">
			<xsl:text disable-output-escaping="yes">y</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 122">
			<xsl:text disable-output-escaping="yes">z</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 123">
			<xsl:text disable-output-escaping="yes">{</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 124">
			<xsl:text disable-output-escaping="yes">|</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 125">
			<xsl:text disable-output-escaping="yes">}</xsl:text>
		</xsl:when>
		<xsl:when test="$ascii = 126">
			<xsl:text disable-output-escaping="yes">~</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$ascii"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:transform>
