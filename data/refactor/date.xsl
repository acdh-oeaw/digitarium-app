<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:local="local"
	xmlns="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="#all"
	version="3.0">
	
	<xsl:template match="tei:w[local:isDay(.)
		and(following-sibling::*[1][self::tei:pc[. = '.']]
			or following-sibling::*[1][self::tei:w[. = 'ten']])
		and following-sibling::*[2][self::tei:w[local:isMonth(.)]]]">
		<xsl:call-template name="date">
			<xsl:with-param name="seq" select="(.,
					following-sibling::node() intersect following-sibling::*[2]/preceding-sibling::node(),
					following-sibling::*[2])" />
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="tei:w[local:isDay(.)
		and following-sibling::*[1][self::tei:w[local:isMonth(.)]]]">
		<xsl:call-template name="date">
			<xsl:with-param name="seq" select="(.,
				following-sibling::node() intersect following-sibling::*[1]/preceding-sibling::node(),
				following-sibling::*[1])" />
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="date">
		<xsl:param name="seq" />
		
		<xsl:variable name="year" select="substring(substring-after(/tei:TEI/@xml:id, 'wd_'), 1, 4)"/>
		
		<xsl:variable name="month">
			<xsl:value-of select="local:getMonth($seq[last()])"/>
		</xsl:variable>
		
		<xsl:variable name="day">
			<xsl:choose>
				<xsl:when test="string-length($seq[1]) = 1">
					<xsl:value-of select="'0' || $seq[1]"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$seq[1]"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<date when="{$year}-{$month}-{$day}"><xsl:sequence select="$seq"/></date>
	</xsl:template>
	
	<xsl:template match="tei:pc[. = '.'
		and following-sibling::*[1][self::tei:w[local:isMonth(.)]]
		and preceding-sibling::*[1][self::tei:w[local:isDay(.)]]]" />
	<xsl:template match="tei:w[. = 'ten'
		and following-sibling::*[1][self::tei:w[local:isMonth(.)]]
		and preceding-sibling::*[1][self::tei:w[local:isDay(.)]]]" />
	
	<xsl:template match="tei:w[local:isMonth(.)
		and (preceding-sibling::*[1][self::tei:w[matches(., '\d{1,2}')]]
		or (preceding-sibling::*[1][self::tei:pc[.='.'] or self::tei:w[.='ten']]
		and preceding-sibling::*[2][self::tei:w[local:isDay(.)]]))]" />
	
	<xsl:template match="text()[(local:isDay(preceding-sibling::*[1])
		or (local:isDay(preceding-sibling::*[2]) and preceding-sibling::*[1][.='.' or .='ten']))
		and local:isMonth(following-sibling::*[1])]" />
	
	<xsl:function name="local:isMonth" as="xs:boolean">
		<xsl:param name="context" as="node()" />
		
		<xsl:choose>
			<xsl:when test="matches($context, '^[JFMASONDIHWLBEC][aeäpukocsrh][nbrilgptvztyau]')
				and xs:integer(local:getMonth($context)) &gt; 0">
				<xsl:sequence select="true()" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="false()" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="local:isDay" as="xs:boolean">
		<xsl:param name="context" />
		<xsl:sequence select="$context castable as xs:integer
			and xs:integer($context) &lt; 32" />
	</xsl:function>
	
	<xsl:function name="local:getMonth" as="xs:string">
		<xsl:param name="seq" />
		<xsl:choose>
			<xsl:when test="contains($seq, 'Jan') or contains($seq, 'Jän')">01</xsl:when>
			<xsl:when test="contains($seq, 'Feb') or contains($seq, 'Hor')">02</xsl:when>
			<xsl:when test="contains($seq, 'Mar') or contains($seq, 'Len')
				or contains($seq, 'Mär') or contains($seq, 'Merz')">03</xsl:when>
			<xsl:when test="contains($seq, 'Apr') or contains($seq, 'Ost')">04</xsl:when>
			<xsl:when test="contains($seq, 'Mai') or contains($seq, 'May')">05</xsl:when>
			<xsl:when test="contains($seq, 'Jun') or contains($seq, 'Bra')">06</xsl:when>
			<xsl:when test="contains($seq, 'Jul') or contains($seq, 'Heu')">07</xsl:when>
			<xsl:when test="contains($seq, 'Aug') or contains($seq, 'Ern')">08</xsl:when>
			<xsl:when test="contains($seq, 'Sep')">09</xsl:when>
			<xsl:when test="contains($seq, 'Okt') or contains($seq, 'Oct')">10</xsl:when>
			<xsl:when test="contains($seq, 'Nov')">11</xsl:when>
			<xsl:when test="contains($seq, 'Dez') or contains($seq, 'Chr')">12</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
</xsl:stylesheet>