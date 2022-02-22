<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	xmlns:local="local"
	exclude-result-prefixes="#all" version="3.0">
	
<!--	<xsl:output indent="yes"/>-->
	
	<xsl:key name="elems" match="tei:p" use="@facs" />
	
	<xsl:template match="/">
		<xsl:text>
</xsl:text>
		<TEI>
			<xsl:attribute name="xml:id">
				<xsl:text>edoc_wd_</xsl:text>
				<xsl:variable name="sd" select="substring-after(//tei:title[@type = 'main'], 'wd')"/>
				<xsl:value-of
					select="substring($sd, 1, 4) || '-' || substring($sd, 5, 2) || '-' || substring($sd, 7, 2)"
				/>
			</xsl:attribute>
			<xsl:text>
	</xsl:text>
			<xsl:apply-templates select="/tei:TEI/tei:teiHeader"/>
			<xsl:text>
	</xsl:text>
			<facsimile>
				<xsl:apply-templates select="/tei:TEI/tei:facsimile/tei:surface" mode="pts"/>
			</facsimile>
			<xsl:text>
	</xsl:text>
			<text>
				<body>
					<xsl:apply-templates select="/tei:TEI/tei:facsimile/tei:surface"/>
				</body>
			</text>
		</TEI>
	</xsl:template>
	
	<xsl:template match="tei:surface[not(descendant::tei:zone[@rendition='TextRegion'])]">
		<div type="page" n="{substring-after(@xml:id, '_')}">
			<pb n="{substring-after(@xml:id, '_')}" facs="{'#'||@xml:id}"/>
		</div>
	</xsl:template>
	<xsl:template match="tei:surface[descendant::tei:zone[@rendition='TextRegion']]">
		<xsl:variable name="maxW" as="xs:integer+" >
			<xsl:variable name="pts" as="xs:integer+">
				<xsl:for-each select="tei:zone[not(@rendition='printspace')]/@points">
					<xsl:variable name="t" select="local:points(current())"/>
					<xsl:sequence select="$t[1], $t[last()]"/>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="sorted" as="xs:integer+">
				<xsl:for-each select="$pts">
					<xsl:sort select="xs:integer(current())" />
					<xsl:value-of select="xs:integer(current())"/>
				</xsl:for-each>
			</xsl:variable>
			<xsl:sequence select="$sorted[1], xs:integer($sorted[last()] - $sorted[1]), $sorted[last()]"/>
		</xsl:variable>
		<div type="page" n="{substring-after(@xml:id, '_')}">
			<!--<m><xsl:value-of select="'(' || $maxW[1] || ', ' || $maxW[2] || ', ' || $maxW[3] || ')'"/></m>
			<ml><xsl:value-of select="$maxW[1]"/></ml>
			<mw><xsl:value-of select="$maxW[2]"/></mw>
			<mr><xsl:value-of select="$maxW[3]"/></mr>
			<xsl:for-each select="tei:surface/tei:zone[not(@rendition='printspace')]/@points">
				<p type="{parent::tei:zone/@subtype}" facs="{parent::*/@xml:id}">
				<xsl:variable name="t" select="local:points(current())"/>
					<l><xsl:value-of select="$t[1]"/></l>
					<r><xsl:value-of select="$t[last()]"/></r>
					<lwr>
						<xsl:variable name="topX" select="$t" />
						<xsl:variable name="topL" select="$topX[1] - $maxW[1]" as="xs:integer"/>
						<xsl:variable name="topR" select="$topX[last()] - $maxW[1]" as="xs:integer"/>
						
						<xsl:variable name="val" select="round($topL * 100 div $maxW[2])"/>
						<xsl:variable name="w" select="$topR - $topL" />
						<xsl:variable name="width" select="round($w * 100 div $maxW[2])"/>
						<xsl:variable name="valR" select="round($topR * 100 div $maxW[2])"/>
						<l><xsl:value-of select="$val"/></l>
						<w><xsl:value-of select="$width"/></w>
						<r><xsl:value-of select="$valR"/></r>
					</lwr>
				</p>
			</xsl:for-each>-->
			
			<pb n="{substring-after(@xml:id, '_')}" facs="{'#'||@xml:id}"/>
			<!-- Angaben in surface/@lrx und @lry sowie graphic/@width und @height verkehrt;
				vgl. https://github.com/Transkribus/TranskribusCore/issues/25; 2017-10-04 DK -->
			
			<!-- 1. alles, was fw ist und am Anfang steht -->
			<!-- TODO Problem, falls Tabelle ohne Überschrift steht? -->
			<xsl:apply-templates select="tei:zone[
				(local:isFw(.) or @rendition = 'Separator' or @subtype = 'header')
				and not(preceding-sibling::tei:zone[local:isContent(.) or @subtype = 'heading'])]">
				<xsl:with-param name="maxW" select="$maxW" as="xs:integer+" />
			</xsl:apply-templates>
			
			<!-- 2. alles, was content ist und vor dem ersten heading; ggf. ist das die ganze Seite -->
			<!-- das inkludiert ggf. auch einen Separator zwischen fw am Kopf und erster Überschrift -->
			<xsl:if test="tei:zone[not(preceding-sibling::tei:zone[local:isHeading(.)])
				and (local:isContent(.)
				or (@rendition='Separator' and preceding-sibling::tei:zone[local:isContent(.)])
				)]">
				<div>
					<xsl:apply-templates select="tei:zone[not(preceding-sibling::tei:zone[local:isHeading(.)])
						and (local:isContent(.)
							or (@rendition='Separator' and preceding-sibling::tei:zone[local:isContent(.)])
						)]">
						<xsl:with-param name="maxW" select="$maxW" as="xs:integer+" />
					</xsl:apply-templates>
				</div>
			</xsl:if>
			
			<!-- 3. falls Überschriften vorhanden, gliedern diese -->
			<xsl:apply-templates select="tei:zone[@subtype = 'heading']">
				<xsl:with-param name="maxW" select="$maxW" as="xs:integer+" />
			</xsl:apply-templates>
			
			<!-- 4. fw am Ende -->
			<xsl:apply-templates select="tei:zone[local:isFw(.)
				and (preceding-sibling::tei:zone[local:isContent(.)])]">
				<!--and not(following-sibling::tei:zone[local:isContent(.)])]">-->
				<xsl:with-param name="maxW" select="$maxW" as="xs:integer+" />
			</xsl:apply-templates>
		</div>
	</xsl:template>

	<xsl:template match="tei:zone[@rendition = 'Graphic']">
		<figure type="graphic" facs="{'#' || @xml:id}"/>
	</xsl:template>

	<xsl:template match="tei:zone[@rendition = 'Separator']">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:variable name="pts" select="local:points(@points)"/>
		<xsl:variable name="width" select="$pts[4] - $pts[1]"/>
		<xsl:choose>
			<xsl:when test="$width div $maxW[2] &gt; 0.1">
				<milestone type="separator" rend="horizontal" unit="section"
					rendition="{'#' || local:getlrc($maxW, @points)}"/>
			</xsl:when>
			<xsl:otherwise>
				<cb rend="solid" n="{$width || '_' || $maxW[2]}"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:zone[@subtype='catch-word']">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:variable name="pFacs" select="'#' || @xml:id"/>
		<xsl:text>
					</xsl:text>
		<fw facs="{$pFacs}" type="catch" rendition="{'#' || local:getlrc($maxW, @points)}">
			<xsl:apply-templates select="//tei:p[@facs = $pFacs]" mode="text"/>
		</fw>
	</xsl:template>
	
	<!-- Titelei -->
	<xsl:template match="tei:zone[@rendition = 'TextRegion' and @subtype='header']">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:variable name="pFacs" select="'#' || @xml:id"/>
		
		<xsl:variable name="elem">
			<xsl:choose>
				<xsl:when test="substring-before(substring-after(@xml:id, '_'), '_') = '1'">title</xsl:when>
				<xsl:when test="contains(@facs, '_1_')">titlePart</xsl:when>
				<xsl:otherwise>fw</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:element name="{$elem}">
			<xsl:attribute name="facs" select="$pFacs" />
			<xsl:attribute name="type">other</xsl:attribute>
			<xsl:attribute name="rendition" select="'#' || local:getlrc($maxW, @points)" />
			<xsl:apply-templates select="//tei:*[@facs = $pFacs]" mode="text"/>
		</xsl:element>
		
		<!-- Linien direkt nach dem Titel sowie ggf. Inhalt -->
		<!--<xsl:if test="following-sibling::tei:zone[1][@rendition = 'Separator']">
			<fw>
				<xsl:attribute name="rendition" select="'#' || local:getlrc($maxW, @points)" />
			<xsl:apply-templates select="following-sibling::tei:zone[1][@rendition = 'Separator']">
				<xsl:with-param name="maxW" select="$maxW" as="xs:integer+" />
			</xsl:apply-templates>
			</fw>
		</xsl:if>-->
		
		<!-- alles nach dem letzten Titelteil und der ersten Inhaltsüberschrift; z.B. Motto nach der Titelei -->
		<xsl:if test="not(following-sibling::tei:zone[1][local:isHeading(.)])
			and following-sibling::tei:zone[local:isHeading(.)]">
			<xsl:for-each select="following-sibling::tei:zone[not(@rendition = 'Separator')]
				intersect following-sibling::tei:zone[local:isHeading(.)][1]/preceding-sibling::tei:zone">
				<xsl:if test="not(@subtype = 'row' and preceding-sibling::*[1]/@subtype = 'row')">
					<fw facs="#{@xml:id}">
						<xsl:attribute name="rendition" select="'#' || local:getlrc($maxW, @points)" />
						<xsl:apply-templates select=".">
							<xsl:with-param name="maxW" select="$maxW" as="xs:integer+" />
						</xsl:apply-templates>
					</fw>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		
		<xsl:if test="not(following-sibling::tei:zone[matches(@subtype, 'header|heading')])
			and following-sibling::tei:zone[@subtype = 'paragraph' or @subtype = 'footnote']">
			<div>
				<xsl:apply-templates select="following-sibling::tei:zone[@subtype = 'paragraph' or @subtype = 'footnote']">
					<xsl:with-param name="maxW" select="$maxW" as="xs:integer+" />
				</xsl:apply-templates>
			</div>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:zone[@rendition = 'TextRegion' and @subtype = 'heading']">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:variable name="pFacs" select="'#' || @xml:id"/>
		<div>
			<head rendition="{'#' || local:getlrc($maxW, @points)}" facs="{$pFacs}">
				<xsl:apply-templates select="//tei:*[@facs = $pFacs]" mode="text"/>
			</head>
			<xsl:choose>
				<xsl:when test="following-sibling::tei:zone[@subtype = 'heading']">
					<xsl:apply-templates
						select="
							following-sibling::tei:zone[not(@subtype = 'heading')] intersect
							following-sibling::tei:zone[@subtype = 'heading'][1]/preceding-sibling::tei:zone"
						>
						<xsl:with-param name="maxW" select="$maxW" as="xs:integer+" />
					</xsl:apply-templates>
				</xsl:when>
				<xsl:otherwise>
					<!-- alle nachfolgenden Absätze, Separatoren, Tabellen; nichts, was fw werden kann -->
					<xsl:apply-templates select="following-sibling::tei:zone[not(local:isHeading(.) or local:isFw(.))]">
						<xsl:with-param name="maxW" select="$maxW" as="xs:integer+" />
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
		</div>
	</xsl:template>
	
	<!-- Tabellen; neu 2017-10-12 DK -->
	<!-- Tabellen aus Transkribus’ Tabellen-Tool -->
	<xsl:template match="tei:zone[@rendition = 'Table']">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:variable name="pFacs" select="'#' || @xml:id"/>
		<xsl:apply-templates select="//tei:table[@facs = $pFacs]">
			<xsl:with-param name="maxW" select="$maxW"/>
		</xsl:apply-templates>
	</xsl:template>
	<!-- einfache Tabellen (jeweils nur eine Zeile je Tabellenzeile: Region = other -->
	<xsl:template match="tei:zone[@rendition = 'TextRegion' and (@subtype = 'other' or @subtype='table')]">
		<xsl:param name="maxW" as="xs:integer+" />
		<table rendition="{'#' || local:getlrc($maxW, @points)}">
			<xsl:apply-templates />
		</table>
	</xsl:template>
	<xsl:template match="tei:zone[@subtype = 'other' or @subtype = 'table']/tei:zone[@rendition = 'Line']">
		<xsl:variable name="pFacs" select="'#' || @xml:id"/>
		<row>
			<xsl:if test="@subtype = 'header'">
				<xsl:attribute name="role">head</xsl:attribute>
			</xsl:if>
			<xsl:variable name="elem" select="//node()[preceding-sibling::tei:lb[1][@facs = $pFacs]]" />
			<xsl:variable name="row">
				<xsl:apply-templates select="$elem" mode="rowSplit" />
			</xsl:variable>
			<xsl:for-each-group select="$row/node()" group-starting-with="local:cellBreak">
				<cell>
					<xsl:choose>
						<xsl:when test="current-group()[1][self::local:cellBreak and @border]">
							<xsl:attribute name="rend">border</xsl:attribute>
							<xsl:apply-templates select="current-group()[not(self::tei:lb)]" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="current-group()[not(self::tei:lb)]" />
						</xsl:otherwise>
					</xsl:choose>
				</cell>
			</xsl:for-each-group>
		</row>
	</xsl:template>
	<xsl:template match="node()" mode="rowSplit">
		<xsl:choose>
			<xsl:when test="self::text()">
				<xsl:analyze-string select="." regex="\|\||\|">
					<xsl:matching-substring>
						<local:cellBreak>
							<xsl:if test=". = '||'">
								<xsl:attribute name="border">1</xsl:attribute>
							</xsl:if>
						</local:cellBreak>
					</xsl:matching-substring>
					<xsl:non-matching-substring>
						<xsl:analyze-string select="." regex="\s+">
							<xsl:matching-substring>
								<xsl:text> </xsl:text>
							</xsl:matching-substring>
							<xsl:non-matching-substring>
								<xsl:value-of select="."/>
							</xsl:non-matching-substring>
						</xsl:analyze-string>
					</xsl:non-matching-substring>
				</xsl:analyze-string>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="." />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="local:cellBreak" />
	
	<xsl:template match="tei:table">
		<xsl:param name="maxW" />
		<xsl:variable name="id" select="substring-after(@facs, '#')"/>
		<xsl:variable name="points" select="//id($id)/@points"/>
		<table rendition="{'#' || local:getlrc($maxW, $points)}">
			<xsl:apply-templates select="@* | *" />
		</table>
	</xsl:template>
	
	<!-- komplexere Tabellen (mehrere Zeilen je Tabellenzeile): je Region Typ "row"; 2017-10-18 DK -->
	<xsl:template match="tei:zone[@subtype = 'row' and preceding-sibling::tei:zone[1][@subtype = 'row']]"/>
	<xsl:template match="tei:zone[@subtype = 'row' and not(preceding-sibling::tei:zone[1][@subtype = 'row'])]">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:variable name="foll" select="following-sibling::tei:zone[not(@subtype) or not(@subtype = 'row')][1]"/>
		<xsl:variable name="lpts">
			<xsl:choose>
				<xsl:when test="following-sibling::tei:*[1][@subtype = 'row']">
					<xsl:value-of select="following-sibling::tei:zone[1]/@points" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@points"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<table rendition="{'#' || local:getlrc($maxW, $lpts)}">
			<xsl:apply-templates select="." mode="row"/>
			<xsl:choose>
				<xsl:when test="count($foll) &gt; 0">
					<xsl:apply-templates select="following-sibling::tei:zone[@subtype = 'row'] intersect
						$foll/preceding-sibling::tei:*" mode="row"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="following-sibling::tei:zone" mode="row"/>
				</xsl:otherwise>
			</xsl:choose>
		</table>
	</xsl:template>
	<xsl:template match="tei:zone[@subtype = 'row']" mode="row">
		<xsl:variable name="myId" select="@xml:id"/>
		<xsl:variable name="elem" select="//tei:p[@facs = '#'||$myId]"/>
		<xsl:variable name="temp" as="node()">
			<local:t>
				<xsl:apply-templates select="$elem" mode="split" />
			</local:t>
		</xsl:variable>
		<xsl:apply-templates select="$temp"/>
	</xsl:template>
	<xsl:template match="@* | *" mode="split">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()" mode="split"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="text()" mode="split">
		<xsl:analyze-string select="." regex="\|\|">
			<xsl:matching-substring>
				<local:ct border="1"/>
			</xsl:matching-substring>
			<xsl:non-matching-substring>
				<xsl:analyze-string select="." regex="\|">
					<xsl:matching-substring>
						<local:ct />
					</xsl:matching-substring>
					<xsl:non-matching-substring>
						<xsl:value-of select="." />
					</xsl:non-matching-substring>
				</xsl:analyze-string>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:template>
	<xsl:template match="local:t">
		<row facs="{tei:p/@facs}">
			<cell><xsl:apply-templates select="tei:p/node()[not(preceding-sibling::local:ct)
				and not(self::local:ct)]"/></cell>
			<xsl:apply-templates select="tei:p/local:ct" />
		</row>
	</xsl:template>
	<xsl:template match="local:ct">
		<cell>
			<xsl:if test="@border">
				<xsl:attribute name="rend">border</xsl:attribute>
			</xsl:if>
			<xsl:variable name="myId" select="generate-id()"/>
			<xsl:apply-templates
				select="following-sibling::node()[generate-id(preceding-sibling::local:ct[1]) = $myId
				and not(self::local:ct)]" />
		</cell>
	</xsl:template>
	<!-- Ende Tabellen -->
	
	<!-- Anfang Listen; 2017-10-31 DK -->
	<xsl:template match="tei:zone[@subtype='list' and preceding-sibling::tei:zone[1][@subtype='list']]"/>
	<xsl:template match="tei:zone[@subtype='list' and not(preceding-sibling::tei:zone[1][@subtype='list'])]">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:variable name="foll" select="following-sibling::tei:zone[not(@subtype) or not(@subtype = 'list')][1]"/>
		<xsl:variable name="items">
			<xsl:choose>
				<xsl:when test="count($foll) &gt; 0">
					<xsl:apply-templates select=". | following-sibling::tei:zone[@subtype='list']
						intersect $foll/preceding-sibling::tei:*" mode="list">
						<xsl:with-param name="maxW" select="$maxW" as="xs:integer+" />
					</xsl:apply-templates>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select=". | following-sibling::tei:zone" mode="list">
						<xsl:with-param name="maxW" select="$maxW" as="xs:integer+" />
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:for-each-group select="$items/node()" group-by="@rendition">
			<list rendition="{current-grouping-key()}">
				<xsl:sequence select="current-group()" />
			</list>
		</xsl:for-each-group>
	</xsl:template>
	<xsl:template match="tei:zone" mode="list">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:variable name="pFacs" select="'#'||@xml:id"/>
		<item facs="{$pFacs}" rendition="#{local:getlrc($maxW, @points)}">
			<xsl:apply-templates select="key('elems', $pFacs)/node()" />
		</item>
	</xsl:template>
	<!-- ENDE Listen -->

	<xsl:template match="tei:zone[@subtype = 'page-number']">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:variable name="pFacs" select="'#' || @xml:id"/>
		<fw facs="{$pFacs}" type="pageNum" rendition="{'#' || local:getlrc($maxW, @points)}">
			<xsl:apply-templates select="//tei:p[@facs = $pFacs]" mode="text"/>
		</fw>
	</xsl:template>

	<!-- not(@subtype) sind meist Absätze, bei denen wegen Aufteilung in Transkribus ein Typ fehlt -->
	<xsl:template match="tei:zone[@rendition='TextRegion' and (@subtype = 'paragraph' or @subtype = 'footnote'
		or not(@subtype))]">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:variable name="lrc" select="local:getlrc($maxW, @points)" />
		<xsl:variable name="pFacs" select="'#' || @xml:id"/>
		<xsl:apply-templates select="//tei:p[@facs = $pFacs]">
			<xsl:with-param name="lrc" select="$lrc" />
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="tei:zone[@rendition = 'printspace']"/>
	
	<xsl:template match="tei:zone[@subtype='signature-mark']">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:variable name="pFacs" select="'#' || @xml:id"/>
		<fw type="sig" facs="{$pFacs}" rendition="{'#' || local:getlrc($maxW, @points)}">
			<xsl:apply-templates select="//tei:p[@facs = $pFacs]" mode="text"/>
		</fw>
	</xsl:template>

	<xsl:template match="tei:*" mode="text">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="tei:p">
		<xsl:param name="lrc" />
		<p rendition="{'#' || $lrc}">
			<xsl:apply-templates select="@*" />
			<xsl:apply-templates />
		</p>
	</xsl:template>
	
	<!-- neben Antiqua auch Hochstellungen berücksichtigen -->
	<xsl:template match="tei:hi">
		<hi>
			<xsl:if test="contains(@rend, 'superscript')">
				<xsl:attribute name="rend">super</xsl:attribute>
			</xsl:if>
			<xsl:if test="contains(@rend, 'Antiqua') or contains(@rend, 'serif')">
				<xsl:attribute name="style">font-family: Antiqua;</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates />
		</hi>
	</xsl:template>
	<xsl:template match="tei:Antiqua">
		<hi style="font-family: Antiqua;">
			<xsl:apply-templates />
		</hi>
	</xsl:template>
	
	<xsl:template match="tei:lb/@n" />
	
	<xsl:template match="tei:surface" mode="pts">
		<xsl:text>
		</xsl:text>
		<surface>
			<xsl:attribute name="xml:id" select="parent::tei:facsimile/@xml:id" />
			<xsl:apply-templates select="@* | *" mode="pts" />
		</surface><!--
		<xsl:text>
		</xsl:text>-->
	</xsl:template>
	<xsl:template match="@*" mode="pts">
		<xsl:sequence select="." />
	</xsl:template>
	<xsl:template match="tei:graphic" mode="pts">
		<xsl:text>
			</xsl:text>
		<xsl:copy>
			<xsl:apply-templates select="@*" />
		</xsl:copy>
	</xsl:template>
	<xsl:template match="tei:zone" mode="pts">
		<xsl:choose>
			<xsl:when test="parent::tei:zone">
				<xsl:text>
				</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>
			</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<zone>
			<xsl:sequence select="@*[not(local-name()='points')]" />
			<xsl:apply-templates select="@points" mode="pts" />
			<xsl:apply-templates select="*" mode="pts" />
			<xsl:if test="not(parent::tei:zone or @rendition=('printspace', 'Graphic', 'Separator'))">
				<xsl:text>
			</xsl:text>
			</xsl:if>
		</zone>
	</xsl:template>
	<xsl:template match="tei:zone/@points" mode="pts">
		<xsl:variable name="x" as="xs:integer+" >
			<xsl:variable name="pts" as="xs:integer+">
				<xsl:variable name="t" select="local:points(.)"/>
				<xsl:sequence select="$t[1], $t[last()]"/>
			</xsl:variable>
			<xsl:variable name="sorted" as="xs:integer+">
				<xsl:for-each select="$pts">
					<xsl:sort select="xs:integer(current())" />
					<xsl:value-of select="xs:integer(current())"/>
				</xsl:for-each>
			</xsl:variable>
			<xsl:sequence select="$sorted[1], xs:integer($sorted[last()] - $sorted[1]), $sorted[last()]"/>
		</xsl:variable>
		<xsl:variable name="y" as="xs:integer+" >
			<xsl:variable name="pts" as="xs:integer+">
				<xsl:variable name="t" select="local:pointsY(.)"/>
				<xsl:sequence select="$t[1], $t[last()]"/>
			</xsl:variable>
			<xsl:variable name="sorted" as="xs:integer+">
				<xsl:for-each select="$pts">
					<xsl:sort select="xs:integer(current())" />
					<xsl:value-of select="xs:integer(current())"/>
				</xsl:for-each>
			</xsl:variable>
			<xsl:sequence select="$sorted[1], xs:integer($sorted[last()] - $sorted[1]), $sorted[last()]"/>
		</xsl:variable>
		<xsl:attribute name="points">
			<xsl:value-of select="$x[1] || ',' || $y[1]"/>
			<xsl:text> </xsl:text>
			<xsl:value-of select="$x[last()] || ',' || $y[1]"/>
			<xsl:text> </xsl:text>
			<xsl:value-of select="$x[last()] || ',' || $y[last()]"/>
			<xsl:text> </xsl:text>
			<xsl:value-of select="$x[1] || ',' || $y[last()]"/>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="text() | * | @*">
		<xsl:copy>
			<xsl:apply-templates select="node() | @*"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:function name="local:getlrc">
		<xsl:param name="maxW" as="xs:integer+" />
		<xsl:param name="pts" />
		
		<xsl:variable name="topX" select="local:points($pts)" as="xs:integer+"/>
		<xsl:variable name="topL" select="$topX[1] - $maxW[1]" as="xs:integer"/>
		<xsl:variable name="topR" select="$topX[last()] - $maxW[1]" as="xs:integer"/>
		
		<xsl:variable name="val" select="round($topL * 100 div $maxW[2])"/>
		<xsl:variable name="w" select="$topR - $topL" />
		<xsl:variable name="width" select="round($w * 100 div $maxW[2])"/>
		<xsl:variable name="valR" select="round($topR * 100 div $maxW[2])"/>
		
		<xsl:variable name="str" select="concat($val, '-', $width, '-', $valR)"/>
		<xsl:choose>
			<xsl:when test="$width &gt;= 90">f</xsl:when>
			<xsl:when test="$val &lt;= 3">l</xsl:when>
			<xsl:when test="$val &gt;= 4 and $valR &lt;= 45 and $width &lt; 40">lc</xsl:when>
			<xsl:when test="$val &gt;= 15 and $valR &lt; 50">lr</xsl:when>
			<xsl:when test="$val &gt; 5 and $val &lt; 40 and $valR &gt;= 50 and $valR &lt;= 91">fc</xsl:when>
			<xsl:when test="$val &lt; 10 and $valR &gt; 91">f</xsl:when>
			<xsl:when test="$val &lt; 20 and $width &lt;= 45">l</xsl:when>
			<xsl:when test="$val &gt;= 60 and $valR &lt;= 90 and $width &lt; 30">rc</xsl:when>
			<xsl:when test="$val &gt;= 59 and $valR &gt;= 95 and $width &lt;= 40">rr</xsl:when>
			<xsl:when test="$val &gt;= 47">r</xsl:when>
			<xsl:when test="$width &lt;= 25 and $val &gt;= 40 and $valR &lt; 65">fc</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat('?', $str, '--', $topL, '-', $topR)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="local:points" as="xs:integer+">
		<xsl:param name="pts" />
		<xsl:choose>
			<xsl:when test="$pts=''">
				<xsl:sequence select="(0, 0)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="vals" select="tokenize($pts, ' ')"/>
				<xsl:for-each select="$vals">
					<xsl:sort select="xs:integer(substring-before(current(), ','))" />
					<xsl:value-of select="xs:integer(substring-before(current(), ','))"/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<xsl:function name="local:pointsY" as="xs:integer+">
		<xsl:param name="pts" />
		<xsl:choose>
			<xsl:when test="$pts=''">
				<xsl:sequence select="(0, 0)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="vals" select="tokenize($pts, ' ')"/>
				<xsl:for-each select="$vals">
					<xsl:sort select="xs:integer(substring-after(current(), ','))" />
					<xsl:value-of select="xs:integer(substring-after(current(), ','))"/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="local:isContent" as="xs:boolean">
		<xsl:param name="elem" as="element()"/>
		<xsl:sequence select="if($elem/@rendition = ('Separator', 'Graphic'))
			then xs:boolean(count($elem/preceding-sibling::tei:zone[local:isContent(.)]))
			else not($elem/@subtype or $elem/@rendition = 'printspace')
			or matches($elem/@subtype, 'list|row|paragraph|table|other|footnote')
			or $elem/@rendition = 'Table'" />
	</xsl:function>
	<xsl:function name="local:isHeading" as="xs:boolean">
		<xsl:param name="elem" as="element()"/>
		<xsl:sequence select="matches($elem/@subtype, 'heading|header')" />
	</xsl:function>
	<xsl:function name="local:isFw" as="xs:boolean">
		<xsl:param name="elem" as="element()"/>
		<xsl:sequence select="matches($elem/@subtype, 'catch-word|page-number|signature-mark')
			or ($elem/@subtype = 'header' and not($elem/preceding-sibling::tei:zone[local:isContent(.)]))" />
	</xsl:function>
</xsl:stylesheet>
