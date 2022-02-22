<xsl:stylesheet xmlns:exist="http://exist.sourceforge.net/NS/exist"
	xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	exclude-result-prefixes="#all" version="3.0"
	xsi:schemaLocation="http://www.w3.org/1999/XSL/Transform http://www.w3.org/2007/schema-for-xslt20.xsd">
	
	<xsl:template match="tei:w[. = 'rc']">
		<w>
			<xsl:attribute name="xml:id" select="@xml:id" />
			<xsl:text>&#xA75B;c</xsl:text>
		</w>
	</xsl:template>
	
	<xsl:template match="tei:w[contains(., 'æ') or contains(., '') or contains(., '&#x0153;')]">
		<w>
			<xsl:attribute name="xml:id" select="@xml:id" />
			<choice>
				<orig><xsl:sequence select="node()"/></orig>
				<reg><xsl:value-of select="replace(replace(replace(replace(normalize-space(string-join(text(), '')), 'æ', 'ae'), '', 'ct'), '&#x0153;', 'oe'), '\s+', '')"/></reg>
			</choice>
		</w>
	</xsl:template>
	
	<xsl:template match="tei:w[ancestor::tei:p and following-sibling::node()[1][self::tei:pc[.='-' or .='=']] and not(following-sibling::tei:w)]">
		<w>
			<xsl:attribute name="xml:id" select="@xml:id" />
			<choice>
				<orig><xsl:value-of select="."/></orig>
				<reg><xsl:value-of select="."/><xsl:value-of select="(following::tei:w[ancestor::tei:p])[1]"/></reg>
			</choice>
		</w>
	</xsl:template>
	
	<xsl:template match="tei:teiHeader">
		<xsl:variable name="jg" select="xs:integer(substring(substring-after(/tei:TEI/@xml:id, 'wd_'), 1, 4))"/>
		<teiHeader>
			<fileDesc>
				<titleStmt>
					<title type="main">
						<xsl:value-of select="//tei:front//tei:w[starts-with(., 'Wien')]"/>
						<xsl:text> </xsl:text>
						<xsl:value-of select="//tei:front//tei:w[starts-with(., 'Wien')]/following::tei:w[1]"/>
					</title>
					<title type="sub">Digitale Edition</title>
					<title type="num">
						<xsl:variable name="num" select="(//tei:front//*[(self::tei:titlePart or self::tei:head)
							and matches(., 'Num|Nr')])[1]" />
						<xsl:value-of select="normalize-space($num)" />
						<xsl:text> </xsl:text>
						<xsl:choose>
							<xsl:when test="matches($num, '\d{4}.+\d{1,2}') or matches($num, '\d{1,2}.+\d{4}')" />
							<xsl:when test="//tei:front//tei:titlePart[matches(., '\d{4}.+\d{1,2}|\d{1,2}.+\d{4}')
								and not(matches(., 'Num|Nr'))]">
								<xsl:value-of select="normalize-space(string-join(//tei:front//tei:titlePart[matches(., '\d+')
									and not(matches(., 'Num|Nr'))], ' '))" />
							</xsl:when>
							<xsl:when test="//tei:titlePart[matches(., '\d{4}')]
								and //tei:titlePart[matches(., '[^|\s]\d{1,2}[^\d]') and not(matches(., 'Num|Nr'))]">
								<xsl:value-of select="normalize-space(//tei:titlePart[matches(., '\d{4}')])"/>
								<xsl:text> </xsl:text>
								<xsl:value-of select="normalize-space(//tei:titlePart[matches(., '[^|^\d]\d{1,2}[^\d]')
									and not(matches(., 'Num|Nr'))])"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="normalize-space((//tei:body//tei:*[(self::tei:head or self::tei:p)
									and matches(., '\d{4}')])[1])" />
							</xsl:otherwise>
						</xsl:choose>
					</title>
					<editor>Resch, Claudia</editor>
					<editor>Kampkaspar, Dario</editor>
					<funder>Austrian Academy of Sciences, go!digital 2.0</funder>
				</titleStmt>
				<publicationStmt>
					<publisher>Austrian Centre for Digital Humanities, Austrian Academy of Sciences</publisher>
					<pubPlace>Vienna, Austria</pubPlace>
					<availability><licence>CC-By-SA 4.0 – https://creativecommons.org/licenses/by-sa/4.0/</licence></availability>
				</publicationStmt>
				<sourceDesc>
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
					<list>
						<item></item>
					</list>
				</sourceDesc>
			</fileDesc>
			<encodingDesc>
				<projectDesc>
					<p>Digitarium – Wien[n]erisches Diarium digital. https://digitarium.acdh.oeaw.ac.at</p>
					<p>Created using Transkribus – model ID 10585</p>
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
					<prefixDef ident="anno" matchPattern=".*(\d{{3}})(\d)(\d{{2}})(\d{{2}})-(\d+)\..*"
						replacementPattern="https://diarium-images.acdh-dev.oeaw.ac.at/$10/$1$2/$3/$1$2$3$4/$1$2$3$4-$5">
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
		</teiHeader>
	</xsl:template>
	
	<xsl:template match="tei:docTitle[not(preceding-sibling::tei:docTitle or preceding-sibling::tei:imprimatur)]">
		<docTitle>
			<xsl:sequence select="tei:titlePart
				| following-sibling::tei:docTitle[not(preceding-sibling::tei:imprimatur)]/tei:titlePart
				| following-sibling::tei:milestone[not(preceding-sibling::tei:imprimatur)]"/>
		</docTitle>
	</xsl:template>
	<xsl:template match="tei:docTitle[preceding-sibling::tei:docTitle and not(preceding-sibling::tei:imprimatur)]" />
	<xsl:template match="tei:docTitle[preceding-sibling::tei:docTitle and preceding-sibling::tei:imprimatur]">
		<xsl:sequence select="tei:titlePart" />
	</xsl:template>
	
	<xsl:template match="tei:front//tei:milestone
		| tei:milestone[preceding-sibling::*[1][self::tei:docTitle]]" />
	
	<xsl:template match="tei:milestone[parent::tei:div[@type='page']]">
		<fw rendition="{@rendition}"><xsl:sequence select="." /></fw>
	</xsl:template>
	
	<xsl:template match="@*">
		<xsl:copy>
			<xsl:apply-templates select="."/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="*">
		<xsl:element name="{local-name()}">
			<xsl:apply-templates select="@* | node()"/>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>