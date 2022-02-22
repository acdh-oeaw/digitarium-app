<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:wdb="https://github.com/dariok/wdbplus"
	exclude-result-prefixes="#all" version="3.0">
	
<!--	<xsl:output indent="yes" />-->
	
	<xsl:template match="/">
		<xsl:apply-templates />
	</xsl:template>
	
	<!-- TODO ändern, wenn neuer TEI-Export eingebaut ist! -->
	<xsl:template match="tei:surface">
		<!-- @ulr und @ulx sind vertauscht; vgl. https://github.com/Transkribus/TranskribusCore/issues/25 -->
		<surface ulx="{@ulx}" uly="{@uly}" lrx="{@lrx}" lry="{@lry}">
			<xsl:attribute name="xml:id" select="@xml:id" />
			<xsl:apply-templates />
		</surface>
	</xsl:template>
	<xsl:template match="tei:graphic">
		<!-- @width und @height sind vertauscht; vgl. https://github.com/Transkribus/TranskribusCore/issues/25 -->
		<graphic url="{'anno:'||@url}" width="{@width}" height="{@height}"/>
	</xsl:template>
	
	<!-- neu 2017-11-22 DK -->
	<xsl:template match="tei:supplied">
		<xsl:variable name="text">
			<text>
				<xsl:choose>
					<xsl:when test="tei:unclear">
						<xsl:value-of select="tei:unclear"/>
						<xsl:if test="following-sibling::node()[1][self::tei:unclear]">
							<xsl:value-of select="following-sibling::*[1]"/>
						</xsl:if>
					</xsl:when>
					<xsl:when test="following-sibling::node()[1][self::tei:unclear]">
						<xsl:value-of select="."/>
						<xsl:value-of select="following-sibling::*[1]"/>
					</xsl:when>
					<xsl:when test="preceding-sibling::node()[1][self::tei:unclear]">
						<xsl:value-of select="preceding-sibling::*[1]"/>
						<xsl:value-of select="."/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates />
					</xsl:otherwise>
				</xsl:choose>
			</text>
		</xsl:variable>
		<unclear>
			<xsl:apply-templates select="$text//text()" />
		</unclear>
	</xsl:template>
	
	<xsl:template match="tei:unclear[preceding-sibling::node()[1][self::tei:supplied]
		or following-sibling::node()[1][self::tei:supplied]]" />
	
	<!-- folgende hi zusammenziehen -->
	<xsl:template match="tei:hi[not(wdb:isFirst(., 'hi'))]" />
	<xsl:template match="tei:hi[wdb:isFirst(., 'hi')]">
		<xsl:variable name="myId" select="generate-id()" />
		<hi>
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates select="node()" mode="copy"/>
			<xsl:apply-templates select="following-sibling::tei:hi[wdb:followMe(., $myId, 'hi')]/node() | 
				following-sibling::tei:hi[wdb:followMe(., $myId, 'hi')]/preceding-sibling::tei:lb[1]" mode="copy" />
		</hi>
	</xsl:template>
	
	<xsl:template match="tei:lb[preceding-sibling::*[1][self::tei:hi]
		and following-sibling::node()[1][self::tei:hi]
		and string-length(normalize-space(preceding-sibling::text()[1])) = 0]" />
	<xsl:template match="tei:lb" mode="copy">
		<xsl:sequence select="." />
	</xsl:template>
	<xsl:template match="tei:hi/node()[not(self::tei:lb)]" mode="copy">
		<xsl:apply-templates select="." />
	</xsl:template>
	
	<xsl:template match="text()[ancestor::tei:text
		and not(normalize-space() = '' and following-sibling::node()[1][self::tei:lb])]">
		<xsl:analyze-string select="." regex="\s+">
			<xsl:matching-substring>
				<xsl:text> </xsl:text>
			</xsl:matching-substring>
			<xsl:non-matching-substring>
				<xsl:analyze-string select="." regex="([^\.,;!?\-=—:/\(\)„“”]+)([\.,;!?\-=—:/\)„“”])?([\)])?">
				<!--<xsl:analyze-string select="." regex="(\w+)([\.,!?\-=—:])?">-->
					<xsl:matching-substring>
						<w><xsl:value-of select="regex-group(1)"/></w>
						<xsl:if test="regex-group(2)">
							<pc><xsl:value-of select="regex-group(2)"/></pc>
						</xsl:if>
						<xsl:if test="regex-group(3)">
							<pc><xsl:value-of select="regex-group(3)"/></pc>
						</xsl:if>
					</xsl:matching-substring>
					<xsl:non-matching-substring>
						<xsl:if test="matches(., '[\.,;!?\-=—:/\(„“”]')">
							<pc><xsl:value-of select="."/></pc>
						</xsl:if>
					</xsl:non-matching-substring>
				</xsl:analyze-string>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:template>
	<!-- Leerstellen vor Umbruch nicht umsetzen; sonst kommt es zu Leerzeichen in gemischten Wörtern hi+normal 
		Vgl. XSpec, T1.4-->
	<xsl:template match="text()[normalize-space() = ''
		and following-sibling::node()[1][self::tei:lb]]" />
	
	<xsl:template match="tei:p | tei:fw">
		<xsl:text>
					</xsl:text>
		<xsl:copy>
			<xsl:apply-templates select="@* | node()" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="tei:hi/@rend">
		<xsl:attribute name="style">
			<xsl:choose>
				<xsl:when test="contains(., 'fontFamily:Antiqua;')">font-family: Antiqua;</xsl:when>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="@*">
		<xsl:copy>
			<xsl:apply-templates select="."/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="*">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:function name="wdb:substring-before-if-ends">
		<xsl:param name="s" as="xs:string"/>
		<xsl:param name="c" as="xs:string"/>
		<xsl:variable name="l" select="string-length($s)" />
		<xsl:value-of select="if(ends-with($s, $c)) then substring($s, 1, $l - 1) else $s"/>
	</xsl:function>
	
	<xsl:function name="wdb:isFirst">
		<xsl:param name="context" as="item()" />
		<xsl:param name="myName" as="xs:string" />
		
		<xsl:variable name="prec" select="$context/preceding-sibling::*[not(self::tei:pb or self::tei:lb)][1]"/>
		
		<xsl:choose>
			<xsl:when test="local-name($context) != $myName"><xsl:sequence select="false()"/></xsl:when>
			<xsl:when test="local-name($prec) = $myName
				and $context/preceding-sibling::node()[1][self::tei:lb or self::tei:pb]
				and $context/preceding-sibling::node()[2][self::text()][normalize-space() = '']">
				<xsl:sequence select="false()" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="true()" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="wdb:followMe" as="xs:boolean">
		<xsl:param name="context" as="item()" />
		<xsl:param name="myID" as="xs:string" />
		<xsl:param name="name" as="xs:string" />
		
		<xsl:variable name="pre" select="$context/preceding-sibling::tei:*[wdb:isFirst(., $name)][1]" />
		<xsl:variable name="text" select="$context/preceding-sibling::tei:lb[1]/preceding-sibling::text()[1]" />
		
		<xsl:sequence select="local-name($context) = $name
			and not(wdb:isFirst($context, $name))
			and $myID = generate-id($pre)
			and string-length(normalize-space($text)) = 0" />
	</xsl:function>
</xsl:stylesheet>