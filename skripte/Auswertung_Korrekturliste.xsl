<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xpath-default-namespace="annotate"
    xmlns:a="annotate"
    exclude-result-prefixes="#all"
    version="2.0">
    <xsl:output method="html"/>
    <xsl:param name="base-uri">https://digitarium-app.acdh-dev.oeaw.ac.at/view.html?id=</xsl:param>
    <xsl:param name="fehler_nach_ausgabe_path">fehler-nach-ausgabe</xsl:param>
    <xsl:function name="a:category" as="xs:string">
        <xsl:param name="entry" as="element(entry)"/>
        <xsl:variable name="c" select="lower-case($entry/cat)"/>
        <xsl:choose>
            <xsl:when test="contains($c,'kursiv')">kursiv</xsl:when>
            <xsl:when test="contains($c,'Linie')">Linie</xsl:when>
            <xsl:when test="contains($c,'Spalte')">Spalte</xsl:when>
            <xsl:when test="contains($c,'rück')">Einrückung</xsl:when>
            <xsl:when test="contains($c,'links')">Linksbündig</xsl:when>
            <xsl:when test="contains($c,'rechts')">Rechtsbündig</xsl:when>
            <xsl:when test="matches($c,'abst[aä]nde?')">Abstände</xsl:when>
            <xsl:when test="contains($c,'zentrier')">Zentriert</xsl:when>
            <xsl:otherwise>Andere</xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:template match="/">
        <xsl:variable name="fehler_nach_ausgabe" as="element(a:ausgabe)+">
            <xsl:for-each-group select="//entry[range/@from!='' and range/@to!='']" group-by="file">
                <xsl:sort select="count(current-group())" order="descending"/>
                <a:ausgabe file="{current-grouping-key()}">
                    <xsl:for-each-group select="current-group()" group-by="a:category(.)">
                        <xsl:sort select="current-grouping-key()" order="ascending"/>
                        <a:fehlerkategorie name="{current-grouping-key()}">
                            <xsl:sequence select="current-group()"/>
                        </a:fehlerkategorie>
                    </xsl:for-each-group>
                </a:ausgabe>
            </xsl:for-each-group>
        </xsl:variable>
        
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <title>Fehleranzahl nach Ausgabe – <xsl:value-of select="format-dateTime(current-dateTime(),'[D].[M].[Y] [h]:[m]')"/></title>
            </head>
            <body>
                <h1>Fehleranzahl nach Ausgabe &amp; Kategorie</h1>
                <p>Stand: <xsl:value-of select="format-dateTime(current-dateTime(),'[D].[M].[Y] [H]:[m]')"/></p>
                <table style="width: 75%;">
                    <thead>
                        <tr style="text-align: left;"> 
                            <th>Ausgabe</th>
                            <th>Anzahl der Fehler</th>
                            <th>Anzahl der Fehler nach Kategorie</th>
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:for-each select="$fehler_nach_ausgabe">
                            <xsl:sort select="count(descendant::entry)" order="descending"/>
                            <xsl:variable name="reportfilename" select="concat(@file,'.html')"/>
                            <tr>
                                <td><a target="_blank" href="{$base-uri}{@file}"><xsl:value-of select="@file"/></a></td>
                                <td><a target="_blank" href="{$fehler_nach_ausgabe_path}/{$reportfilename}"><xsl:value-of select="count(descendant::entry)"/></a></td>
                                <td>
                                    <ul>
                                        <xsl:for-each select="fehlerkategorie">
                                            <xsl:variable name="cat" select="@name"/>
                                           <li>
                                               <b><xsl:value-of select="@name"/>:</b><xsl:text> </xsl:text><a href="{$fehler_nach_ausgabe_path}/{$reportfilename}#{$cat}"><xsl:value-of select="count(entry)"/></a>
                                           </li>
                                        </xsl:for-each>
                                    </ul>
                                </td>
                            </tr>
                        </xsl:for-each>
                    </tbody>
                </table>
            </body>
        </html>
        
        
        <xsl:for-each select="$fehler_nach_ausgabe">
            <xsl:variable name="file" select="@file"/>
            <xsl:result-document href="{$fehler_nach_ausgabe_path}/{@file}.html" method="html">
                <html xmlns="http://www.w3.org/1999/xhtml">
                    <head>
                        <title>Fehler in <xsl:value-of select="@file"/> – Stand: <xsl:value-of select="format-dateTime(current-dateTime(),'[D].[M].[Y] [h]:[m]')"/></title>
                    </head>
                    <body>
                        <h1>Fehler in <i><xsl:value-of select="@file"/></i> – Stand: <xsl:value-of select="format-dateTime(current-dateTime(),'[D].[M].[Y] [h]:[m]')"/></h1>
                        <xsl:for-each select="fehlerkategorie">
                            <xsl:sort select="@name" order="descending"/>
                            <h2 id="{@name}"><xsl:value-of select="@name"/></h2>
                            <ul>
                                <xsl:for-each select="entry">
                                    <li><code><xsl:value-of select="cat"/></code> – <a href="{concat($base-uri,$file,'#',range/@from)}"><xsl:value-of select="range/@from"/><xsl:if test="range/@from != range/@to">–<xsl:value-of select="range/@to"/></xsl:if></a></li>
                                </xsl:for-each>
                            </ul>
                        </xsl:for-each>
                    </body>
                </html>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>