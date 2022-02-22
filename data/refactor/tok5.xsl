<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="#all"
	version="3.0">
	
	<xsl:template match="/">
		<xsl:processing-instruction name="xml-model">href="/exist/apps/edoc/data/schema/diarium.sch"</xsl:processing-instruction>
		<xsl:text>
</xsl:text>
		<xsl:processing-instruction name="xml-model">href="/exist/apps/edoc/data/schema/diarium.rnc"</xsl:processing-instruction>
		<xsl:text>
</xsl:text>
		<xsl:apply-templates select="node()" />
	</xsl:template>
	
	<xsl:template match="tei:teiHeader">
		<xsl:text>
	</xsl:text>
		<teiHeader>
			<xsl:apply-templates />
			<xsl:text>
		</xsl:text>
			<revisionDesc status="draft">
				<list>
					
				</list>
			</revisionDesc>
		</teiHeader>
	</xsl:template>
	
	<xsl:template match="tei:facsimile | tei:text">
		<xsl:text>
	</xsl:text>
		<xsl:element name="{local-name()}">
			<xsl:apply-templates select="@* | *"/>
			<xsl:text>
	</xsl:text>
		</xsl:element>
	</xsl:template>
	<xsl:template match="tei:teiHeader/* | tei:facsimile/* | tei:text/*">
		<xsl:text>
		</xsl:text>
		<xsl:element name="{local-name()}">
			<xsl:apply-templates select="@* | *"/>
			<xsl:text>
		</xsl:text>
		</xsl:element>
	</xsl:template>
	<xsl:template match="tei:teiHeader/*/* | tei:facsimile/*/* | tei:text/*/*">
		<xsl:text>
			</xsl:text>
		<xsl:element name="{local-name()}">
			<xsl:apply-templates select="@*" />
			<xsl:if test="*">
				<xsl:text>
					</xsl:text>
				<xsl:apply-templates select="*"/>
				<xsl:text>
				</xsl:text>
			</xsl:if>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:list">
		<list>
			<xsl:apply-templates select="@* | * | comment()" />
		</list>
	</xsl:template>
	
	<xsl:template match="tei:*">
		<xsl:variable name="num">
			<xsl:choose>
				<xsl:when test="self::tei:div">
					<xsl:value-of select="'d' || (count(preceding::tei:div | ancestor::tei:div) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:p">
					<xsl:value-of select="'p' || (count(preceding::tei:p) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:cell">
					<xsl:value-of select="'cell' || (count(preceding::tei:cell) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:item">
					<xsl:value-of select="'i' || (count(preceding::tei:item) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:titlePart or self::tei:imprimatur">
					<xsl:value-of select="'tit' || (count(preceding::tei:titlePart | preceding::tei:imprimatur) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:opener or self::tei:closer or self::tei:postscript">
					<xsl:value-of select="'opc' || (count(preceding::tei:opener | preceding::tei:closer | preceding::tei:postscript) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:epigraph or self::tei:salute">
					<xsl:value-of select="'eps' || (count(preceding::tei:epigraph | preceding::tei:salute) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:l">
					<xsl:value-of select="'l' || (count(preceding::tei:l) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:note[@type='footnote']">
					<xsl:value-of select="'nn' || (count(preceding::tei:note[@type='footnote']) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:pb">
					<xsl:value-of select="'pag' || (count(preceding::tei:pb) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:lb">
					<xsl:value-of select="'z' || (count(preceding::tei:lb) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:cit">
					<xsl:value-of select="'cit' || (count(preceding::tei:cit) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:head or self::tei:label">
					<xsl:value-of select="'hl' || (count(preceding::tei:label | preceding::tei:head) + 1)"/>
				</xsl:when>
				<xsl:when test="self::tei:list">
					<xsl:text>li</xsl:text>
					<xsl:number level="any" />
				</xsl:when>
				<xsl:when test="self::tei:fw">
					<xsl:text>fw</xsl:text>
					<xsl:number level="any" />
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="self::tei:w[tei:lb] and not(matches(preceding-sibling::text()[1], '[\r\n]'))">
				<xsl:text>
						</xsl:text>
			</xsl:when>
			<xsl:when test="self::tei:head[parent::tei:div[not(@type='page')]]">
				<xsl:text>
					</xsl:text>
			</xsl:when>
			<xsl:when test="preceding-sibling::node()[1][self::tei:pb]">
				<xsl:text>
				</xsl:text>
			</xsl:when>
			<xsl:when test="self::tei:div[not(@type='page')] and preceding-sibling::*[1][self::tei:div]">
				<xsl:text>
				</xsl:text>
			</xsl:when>
			<xsl:when test="self::tei:div[@type='page']">
				<xsl:text>
			</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:element name="{local-name()}">
			<xsl:if test="not(@xml:id) and string-length($num) &gt; 0">
				<xsl:attribute name="xml:id" select="$num" />
			</xsl:if>
			<xsl:apply-templates select="@* | node()" />
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:title[@type='num']">
		<!--<xsl:text>
				</xsl:text>-->
		<title type="num">
			<xsl:variable name="num" select="analyze-string(., 'N[ur][mo]\.? \(?(\d+)')" />
			<xsl:variable name="dates" select="analyze-string(string-join($num/*:non-match, ' '), '[^|^\d](\d{1,2})[^\d] ?([\wä]+)')"/>
			<xsl:variable name="year" select="' ' || analyze-string(string-join($num/*:non-match, ''), '\d{4}')//*:match[1]" />
			<xsl:variable name="coverage" as="xs:string*">
				<xsl:for-each select="$dates/*:match">
					<xsl:variable name="month">
						<xsl:choose>
							<xsl:when test="matches(*:group[2], 'Jan|Jän|Jen')"> Jänner</xsl:when>
							<xsl:when test="matches(*:group[2], 'Feb|Hor')"> Februar</xsl:when>
							<xsl:when test="matches(*:group[2], 'Mar|Len|Mär')"> März</xsl:when>
							<xsl:when test="matches(*:group[2], 'Apr|Ost')"> April</xsl:when>
							<xsl:when test="matches(*:group[2], 'Mai|May|Maj')"> Mai</xsl:when>
							<xsl:when test="matches(*:group[2], 'Jun|Bra')"> Juni</xsl:when>
							<xsl:when test="matches(*:group[2], 'Jul|Heu')"> Juli</xsl:when>
							<xsl:when test="matches(*:group[2], 'Aug|Ern')"> August</xsl:when>
							<xsl:when test="matches(*:group[2], 'Sep')"> September</xsl:when>
							<xsl:when test="matches(*:group[2], 'Okt|Oct')"> Oktober</xsl:when>
							<xsl:when test="matches(*:group[2], 'Nov')"> November</xsl:when>
							<xsl:when test="matches(*:group[2], 'Dez|Chr|Dec')"> Dezember</xsl:when>
						</xsl:choose>
					</xsl:variable>
					<xsl:value-of select="*:group[1] || '.' || $month"/>
				</xsl:for-each>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="count($coverage) &gt; 0">
					<xsl:value-of select="'Nr. ' || $num/*:match[1]/*:group[1] || ', ' || string-join($coverage, '–') || $year"/>
				</xsl:when>
				<xsl:when test="$num/*:match">
					<xsl:value-of select="'Nr. ' || $num/*:match[1]/*:group[1]"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space(.)"/>
				</xsl:otherwise>
			</xsl:choose>
		</title>
	</xsl:template>
	
	<xsl:template match="node() | @*">
		<xsl:copy>
			<xsl:apply-templates select="node() | @*"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>