<xsl:stylesheet xmlns:exist="http://exist.sourceforge.net/NS/exist"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mets="http://www.loc.gov/METS/"
	xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:html="http://www.w3.org/1999/xhtml"
	xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	exclude-result-prefixes="xsl tei mets xlink exist xsi html" version="2.0"
	xsi:schemaLocation="http://www.w3.org/1999/XSL/Transform http://www.w3.org/2007/schema-for-xslt20.xsd">

	<!-- Bearbeiter DK: Dario Kampkaspar, dario.kampkaspar@oeaw.ac.at -->
	<!-- übernommen für Wiennerisches Diarium; 2017-04-13 DK -->

	<xsl:output method="html"/>

	<!-- Name und Inhalt angepaßt für Verwendung auf WDB Classic und eXist; 2016-07-14 DK -->
	<xsl:variable name="viewURL">
		<xsl:text>/exist/apps/edoc/view.html</xsl:text>
	</xsl:variable>

	<!-- angepaßt für Verwendung auf WDB Classic und eXist; 2016-07-14 DK -->
	<xsl:variable name="baseDir">
		<xsl:text>/exist/apps/edoc/data</xsl:text>
	</xsl:variable>

	<xsl:template match="tei:gap">
		<xsl:text>〈…〉</xsl:text>
	</xsl:template>

	<xsl:template match="tei:supplied | tei:unclear">
		<xsl:text>⟨</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>⟩</xsl:text>
	</xsl:template>

	<!-- Tabellen -->
	<xsl:template match="tei:table">
		<table>
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="@rend"><xsl:value-of select="@rend"/></xsl:when>
					<xsl:otherwise><xsl:text>noborder</xsl:text></xsl:otherwise>
				</xsl:choose>
				<xsl:if test="tei:row[1]/tei:cell[1][@role = 'head' or @role = 'label']">
					<xsl:text> firstColumnLabel</xsl:text>
				</xsl:if>
			</xsl:attribute>
			<xsl:if test="@style">
				<xsl:attribute name="style" select="@style" />
			</xsl:if>
			<xsl:apply-templates/>
		</table>
	</xsl:template>
	<xsl:template match="tei:row">
		<tr>
			<xsl:apply-templates select="@rend" />
			<xsl:apply-templates select="tei:cell"/>
		</tr>
	</xsl:template>
	<xsl:template match="tei:cell">
		<xsl:variable name="elem">
			<xsl:choose>
				<xsl:when test="parent::tei:row[@role = 'head' or @role = 'label']">th</xsl:when>
				<xsl:otherwise>td</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="pos" select="position()"/>
		<xsl:element name="{$elem}">
			<xsl:apply-templates select="@xml:id" />
			<xsl:if test="(not(@rend) and
				parent::tei:row/preceding-sibling::tei:row[@role = 'head' or @role = 'label'][1]/tei:cell[$pos]/@rend = 'border')
					or @rend = 'border'">
				<xsl:attribute name="style">border-left: 0.5px solid black;</xsl:attribute>
			</xsl:if>
			<xsl:if test="(not(@rend) and
				parent::tei:row/preceding-sibling::tei:row[@role = 'head' or @role = 'label'][1]/tei:cell[$pos]/@rend = 'dborder')
				or @rend = 'dborder'">
				<xsl:attribute name="style">border-left: 3px double black;</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="@rendition" />
			<xsl:if test="@cols">
				<xsl:attribute name="colspan" select="@cols" />
			</xsl:if>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	<!-- Ende Tabellen -->
	
	<xsl:template match="@rend">
		<xsl:attribute name="class" select="normalize-space()" />
	</xsl:template>
</xsl:stylesheet>
