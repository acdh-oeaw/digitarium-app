<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="#all"
	version="2.0">
	
	<xsl:template match="/">
		<xsl:text>
</xsl:text>
		<xsl:processing-instruction name="xml-model">href="/exist/apps/edoc/data/schema/diarium.rnc"</xsl:processing-instruction>
		<xsl:text>
</xsl:text>
		<xsl:processing-instruction name="xml-model">href="/exist/apps/edoc/data/schema/diarium.sch"</xsl:processing-instruction>
		<xsl:text>
</xsl:text>
		<xsl:apply-templates select="tei:TEI" />
		<xsl:text>
</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:div[@type='page']">
		<xsl:text>
			</xsl:text>
		<xsl:copy>
			<xsl:apply-templates select="@* | *"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="tei:w">
		<xsl:if test="tei:lb">
			<xsl:text>
						</xsl:text>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="starts-with(., '(')">
				<pc>(</pc><w xml:id="{@xml:id}"><xsl:value-of select="substring-after(., '(')"/></w>
			</xsl:when>
			<xsl:when test=". = ')'">
				<pc>)</pc>
			</xsl:when>
			<xsl:when test="ends-with(., ')')">
				<w xml:id="{@xml:id}"><xsl:value-of select="substring-before(., ')')"/></w><pc>)</pc>
			</xsl:when>
			<xsl:when test=". = ';'">
				<pc xml:id="{@xml:id}">;</pc>
			</xsl:when>
			<xsl:when test=". = 'rc'">
				<w xml:id="{@xml:id}">&#xA75B;c</w>
			</xsl:when>
			<xsl:when test="contains(., 'æ') or contains(., '') or contains(., '&#x0153;')">
				<w xml:id="{@xml:id}">
					<choice>
						<orig><xsl:sequence select="node()"/></orig>
						<reg><xsl:value-of select="replace(replace(replace(replace(normalize-space(string-join(text(), '')), 'æ', 'ae'), '', 'ct'), '&#x0153;', 'oe'), '\s+', '')"/></reg>
					</choice>
				</w>
			</xsl:when>
			<xsl:when test=". = '&amp;'">
				<pc xml:id="{@xml:id}">&amp;</pc>
			</xsl:when>
			<xsl:when test="ancestor::tei:p and following-sibling::*[1][self::tei:pc[.='-' or .='=']] and not(following-sibling::tei:w)">
				<w xml:id="{@xml:id}">
					<choice>
						<orig><xsl:value-of select="."/></orig>
						<reg><xsl:value-of select="."/><xsl:value-of select="(following::tei:w[ancestor::tei:p])[1]"/></reg>
					</choice>
				</w>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<xsl:apply-templates select="@* | node()" />
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:teiHeader">
		<xsl:variable name="jg" select="xs:int(substring(substring-after(/tei:TEI/@xml:id, 'wd_'), 1, 4))"/>
		<teiHeader>
			<fileDesc>
				<titleStmt>
					<xsl:sequence select="tei:fileDesc/tei:titleStmt/tei:title[@type='main']"/>
					<title type="sub">Digitale Edition</title>
					<xsl:comment>TODO Prüfen: Anpassen auf Nr...</xsl:comment>
					<xsl:apply-templates select="tei:fileDesc/tei:titleStmt/tei:title[@type='num']"/>
					<editor>Resch, Claudia</editor>
					<editor>Kampkaspar, Dario</editor>
					<funder>Austrian Academy of Sciences, go!digital 2.0</funder>
				</titleStmt>
				<publicationStmt>
					<publisher>Austrian Centre for Digital Humanities, Austrian Academy of Sciences</publisher>
					<pubPlace>Vienna, Austria</pubPlace>
					<availability><licence>CC-By-SA 4.0 – https://creativecommons.org/licenses/by-sa/4.0/</licence></availability>
				</publicationStmt>
				<sourceDesc default="false">
					<biblStruct>
						<monogr>
							<idno><xsl:value-of select="substring-before(descendant::tei:title[@type='num'], ',')"/></idno>
							<title>
								<date type="published">
									<xsl:attribute name="when" select="substring-after(/tei:TEI/@xml:id, 'wd_')" />
								</date>
								<date type="run" notBefore="" notAfter="" />
							</title>
							<imprint><publisher>
								<xsl:choose>
									<xsl:when test="$jg &lt; 1722">Johann Baptist Schönwetter</xsl:when>
									<xsl:otherwise>Johann Peter van Ghelen</xsl:otherwise>
								</xsl:choose>
							</publisher></imprint>
						</monogr>
						<series>
							<title>Wiennerisches Diarium –
								<date when="{$jg}">Jahrgang <xsl:value-of select="$jg" /></date></title>
						</series>
						<series>
							<title>Wiener Zeitung</title>
						</series>
					</biblStruct>
				</sourceDesc>
			</fileDesc>
			<encodingDesc>
				<projectDesc>
					<p>Digitarium – Wien[n]erisches Diarium digital. https://diarium.acdh.oeaw.ac.at</p>
					<p>Created using Transkribus – model ID 804</p>
				</projectDesc>
				<tagsDecl>
					<rendition xml:id="f">Full width text, aligned left</rendition>
					<rendition xml:id="fc">Full width text, centered</rendition>
					<rendition xml:id="fh">Full width text, with hanging indent</rendition>
					<rendition xml:id="fr">Full width text, aligned right</rendition>
					<rendition xml:id="l">Text aligned left in a full width region</rendition>
					<rendition xml:id="r">Text aligned right in a full width region</rendition>
					<rendition xml:id="ll">Text aligned left (or justified) in a left column</rendition>
					<rendition xml:id="lc">Text centered in a left column</rendition>
					<rendition xml:id="lr">Text aligned right in a left column</rendition>
					<rendition xml:id="lh">Text aligned left (or justified) in a left column with the first line hanging</rendition>
					<rendition xml:id="rl">Text aligned left (or justified) in a right column</rendition>
					<rendition xml:id="rc">Text centered in a right column</rendition>
					<rendition xml:id="rr">Text aligned right in a right column</rendition>
					<rendition xml:id="rh">Text aligned left (or justified) in a right column with the first line hanging</rendition>
					<rendition xml:id="c">Text within the middle of a three column region, aligned left</rendition>
					<rendition xml:id="cl">Text within the middle of a three column region, aligned left</rendition>
					<rendition xml:id="cc">Text centered in a middle or centered column</rendition>
					<rendition xml:id="cr">Text aligned right in a middle or centered column</rendition>
					<rendition xml:id="ch">Text aligned left (or justified) in a middle or centered column with the first line hanging</rendition>
				</tagsDecl>
				<listPrefixDef>
					<!--<prefixDef ident="anno" matchPattern="0+(\d+)_(\d+)-.+\.png" replacementPattern="http://anno.onb.ac.at/cgi-content/annoshow?call=wrz|$2|$1|33.0|0">-->
					<prefixDef ident="anno" matchPattern="\d+_(\d{{3}})(\d)(\d{{2}})(\d{{2}})-(\d+)\.png" replacementPattern="https://diarium-images.acdh-dev.oeaw.ac.at/$10/$1$2/$3/$1$2$3$4/$1$2$3$4-$5/">
						<p>Ggf. nachbearbeitete ANNO-Bilder auf Diarium-IIIF</p>
					</prefixDef>
				</listPrefixDef>
			</encodingDesc>
			<profileDesc>
				<langUsage>
					<language ident="de-AT-Goth">18th century German as used in Austria (Vienna) in broken script</language>
					<language ident="fr">18th century French</language>
					<language ident="it">18th century Italian</language>
					<language ident="la">Latin</language>
				</langUsage>
				<textClass>
					<keywords scheme="https://d-nb.info/gnd/">
						<term ref="https://d-nb.info/gnd/4067510-5/about/lds.rdf">Zeitung</term>
					</keywords>
				</textClass>
			</profileDesc>
			<revisionDesc status="draft">
				<list>
					<item>Korrektur durch Dienstleister</item>
					<xsl:comment>&lt;item&gt;2. Korrekturdurchlauf&lt;/item&gt;</xsl:comment>
					<xsl:comment>&lt;item&gt;3. Korrekturdurchlauf&lt;/item&gt;</xsl:comment>
				</list>
			</revisionDesc>
		</teiHeader>
	</xsl:template>
	
	<xsl:template match="tei:title[@type = 'num']">
		<title type="num">
			<xsl:variable name="num" select="analyze-string(normalize-space(), 'N\w+\.?\s+(\d+)\.*[A-Za-z ]+(\d+)\.+ (\w+)\.?\s+(\d+)')" />
			<xsl:variable name="month">
				<xsl:choose>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Jan')">Jänner</xsl:when>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Feb') or starts-with($num//*:group[@num=4], 'Horn')">Februar</xsl:when>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Mar') or starts-with($num//*:group[@num=4], 'Lenz')">März</xsl:when>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Apr') or starts-with($num//*:group[@num=4], 'Oste')">April</xsl:when>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Mai')">Mai</xsl:when>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Jun') or starts-with($num//*:group[@num=4], 'Brac')">Juni</xsl:when>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Jul') or starts-with($num//*:group[@num=4], 'Heum')">Juli</xsl:when>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Aug') or starts-with($num//*:group[@num=4], 'Ernt')">August</xsl:when>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Sep')">September</xsl:when>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Okt') or starts-with($num//*:group[@nr=3], 'Oct')">Oktober</xsl:when>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Nov')">November</xsl:when>
					<xsl:when test="starts-with($num//*:group[@nr=3], 'Dez')">Dezember</xsl:when>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:value-of select="'Nr. ' || $num//*:group[@nr='1'] || ', ' || $num//*:group[@nr=2] || '. ' || $month || ' ' || $num//*:group[@nr=4]"/>
		</title>
	</xsl:template>
	
	<xsl:template match="tei:facsimile[1]">
		<facsimile>
			<xsl:apply-templates select="tei:surface" />
			<xsl:apply-templates select="following-sibling::tei:facsimile/tei:surface" />
		</facsimile>
	</xsl:template>
	<xsl:template match="tei:facsimile[preceding-sibling::tei:facsimile]" />
	
	<xsl:template match="tei:surface">
		<xsl:text>
		</xsl:text>
		<surface xml:id="{parent::tei:facsimile/@xml:id}">
			<xsl:apply-templates select="@* | node()" />
		</surface>
	</xsl:template>
	
	<xsl:template match="tei:milestone[parent::tei:div[@type='page']]">
		<fw rendition="{@rendition}"><xsl:sequence select="." /></fw>
	</xsl:template>
	
	<xsl:template match="text()[normalize-space() = '' and following-sibling::node()[1][self::tei:pc[.=',' or .='.' or .='=' or .=';' or .=':' or .='!' or .='-' or .=')']]]"/>
	<xsl:template match="text()[normalize-space() = '' and preceding-sibling::node()[1][self::tei:pc[.='=' or .='-' or .='(']] and not(following-sibling::tei:w[1][normalize-space() = 'und'])]"/>
	<xsl:template match="text()[normalize-space() = '' and (parent::tei:hi or parent::tei:unclear) and (not(following-sibling::node()) or not(preceding-sibling::node()))]" />
	<xsl:template match="text()[normalize-space() = '' and parent::tei:w and following-sibling::node()[1][self::tei:lb]]" />
	<xsl:template match="text()[normalize-space() = '' and preceding-sibling::node()[1][self::tei:lb] and following-sibling::node()[1][self::tei:w or self::tei:pc]]" />
	
	<xsl:template match="node() | @*">
		<xsl:copy>
			<xsl:apply-templates select="node() | @*" />
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>