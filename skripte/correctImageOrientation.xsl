<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all"
    version="2.0">
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:surface[xs:integer(@lrx) gt xs:integer(@lry)]">
        <xsl:copy>
            <xsl:sequence select="@* except (@lrx, @lry)"/>
            <xsl:attribute name="lrx" select="@lry"/>
            <xsl:attribute name="lry" select="@lrx"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:graphic[xs:integer(substring-before(@width,'px')) gt xs:integer(substring-before(@height,'px'))]">
        <xsl:copy>
            <xsl:sequence select="@* except (@width, @height)"/>
            <xsl:attribute name="width" select="@height"/>
            <xsl:attribute name="height" select="@width"/>
            <xsl:sequence select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>