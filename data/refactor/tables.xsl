<xsl:stylesheet version="2.0" exclude-result-prefixes="#all"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0">
    
    <xsl:template match="tei:cell">
        <cell>
            <xsl:if test="preceding-sibling::tei:cell">
                <xsl:attribute name="rend">border</xsl:attribute>
            </xsl:if>
            <xsl:if test="normalize-space() castable as xs:integer">
                <xsl:attribute name="rendition">#r</xsl:attribute>
            </xsl:if>
            <xsl:sequence select="@xml:id | node()" />
        </cell>
    </xsl:template>
    
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" />
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>