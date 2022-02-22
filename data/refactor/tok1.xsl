<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all"
    version="2.0">
    
    <xsl:template match="tei:pc[. = '//' or .=',,']" />
    
    <xsl:template match="tei:p[tei:pc[. = '//' or .=',,']]">
        <p>
            <xsl:apply-templates select="@*" />
            <quote>
                <xsl:apply-templates />
            </quote>
        </p>
    </xsl:template>
    
    <xsl:template match="tei:w[. = '&amp;']">
        <pc>&amp;</pc>
    </xsl:template>
    
    <xsl:template match="text()[preceding-sibling::node()[1][self::tei:pc[. = '//']]]">
        <xsl:value-of select="substring(., 2)"/>
    </xsl:template>
	
	<xsl:template match="tei:w[following-sibling::node()[1][self::tei:unclear]
		and not(preceding-sibling::node()[1][self::tei:unclear])]">
		<xsl:choose>
			<xsl:when test="count(following-sibling::*[1]/tei:w) = 0">
				<w>
					<xsl:value-of select="."/>
					<unclear><xsl:sequence select="following-sibling::*[1]/*" /></unclear>
				</w>
			</xsl:when>
			<xsl:when test="count(following-sibling::*[1]/tei:w) = 1">
				<w>
					<xsl:value-of select="."/>
					<unclear>
						<xsl:value-of select="following-sibling::*[1]/tei:w"/>
						<xsl:if test="following-sibling::*[1]/tei:pc[.='-' or .='=']">
							<xsl:sequence select="following-sibling::*[1]/tei:pc"></xsl:sequence>
						</xsl:if>
					</unclear>
					<!-- (w)(unclear)(w); XSpec T1.5 -->
					<xsl:if test="following-sibling::node()[2][self::tei:w]">
						<xsl:value-of select="following-sibling::node()[2]"/>
						<xsl:if test="following-sibling::node()[3][self::tei:unclear]">
							<unclear><xsl:value-of select="following-sibling::node()[3]"/></unclear>
						</xsl:if>
					</xsl:if>
				</w>
				<xsl:if test="following-sibling::*[1]/tei:pc[not(.='-' or .='=')]">
					<xsl:sequence select="following-sibling::*[1]/tei:pc"></xsl:sequence>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<w>
					<xsl:value-of select="."/>
					<unclear>
						<xsl:value-of select="following-sibling::*[1]/tei:w[1]"/>
						<xsl:if test="following-sibling::*[1]/tei:w[1]/following-sibling::*[1][self::tei:pc[.='-' or .='=']]">
							<xsl:sequence select="following-sibling::*[1]/tei:pc[1]"></xsl:sequence>
						</xsl:if>
					</unclear>
				</w>
				<xsl:if test="following-sibling::*[1]/tei:w[1]/following-sibling::*[1][self::tei:pc[not(.='-' or .='=')]]">
					<xsl:sequence select="following-sibling::*[1]/tei:pc[1]"></xsl:sequence>
				</xsl:if>
				<unclear>
					<xsl:choose>
						<xsl:when test="following-sibling::tei:unclear[1]/*[2][self::tei:pc[.='-' or .='=']]">
							<xsl:apply-templates select="following-sibling::tei:unclear[1]/node()[count(preceding-sibling::tei:*) = 2]" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="following-sibling::tei:unclear[1]/node()[preceding-sibling::tei:w]" />
						</xsl:otherwise>
					</xsl:choose>
				</unclear>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:w[preceding-sibling::node()[1][self::tei:unclear]
		and not(following-sibling::node()[1][self::tei:unclear])
		and not(preceding-sibling::node()[2][self::tei:w])]">
		<xsl:choose>
			<xsl:when test="count(preceding-sibling::*[1]/tei:w) = 1">
				<xsl:if test="preceding-sibling::*[1]/tei:pc[not(.='-' or .='=')]">
					<xsl:sequence select="preceding-sibling::*[1]/tei:pc"></xsl:sequence>
				</xsl:if>
				<w>
					<unclear>
						<xsl:value-of select="preceding-sibling::*[1]/tei:w"/>
						<xsl:if test="preceding-sibling::*[1]/tei:pc[.='-' or .='=']">
							<xsl:sequence select="preceding-sibling::*[1]/tei:pc"></xsl:sequence>
						</xsl:if>
					</unclear>
					<xsl:value-of select="."/>
				</w>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="preceding-sibling::*[1]/tei:w[1]/preceding-sibling::*[1][self::tei:pc[not(.='-' or .='=')]]">
					<xsl:sequence select="preceding-sibling::*[1]/tei:pc[1]"></xsl:sequence>
				</xsl:if>
				<unclear>
					<!--<xsl:choose>
						<xsl:when test="preceding-sibling::tei:unclear[1]/*[2][self::tei:pc[.='-' or .='=']]">
							<xsl:apply-templates select="preceding-sibling::tei:unclear[1]/node()[count(preceding-sibling::tei:*) = 2]" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="preceding-sibling::tei:unclear[1]/node()[preceding-sibling::tei:w]" />
						</xsl:otherwise>
					</xsl:choose>-->
					<xsl:apply-templates select="preceding-sibling::tei:unclear[1]/node()[following-sibling::tei:w]" />
				</unclear>
				<xsl:text> </xsl:text>
				<w>
					<unclear>
						<xsl:value-of select="preceding-sibling::*[1]/tei:w[last()]"/>
						<xsl:if test="preceding-sibling::*[1]/tei:w[last()]/preceding-sibling::*[1][self::tei:pc[.='-' or .='=']]">
							<xsl:sequence select="preceding-sibling::*[1]/tei:pc[last()]"></xsl:sequence>
						</xsl:if>
					</unclear>
					<xsl:value-of select="."/>
				</w>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:cell[parent::tei:row]">
		<cell>
			<xsl:choose>
				<xsl:when test="count(*)=1 and *[1][self::tei:hi]">
					<hi>
						<xsl:apply-templates select="tei:hi/@*" />
						<xsl:apply-templates select="tei:hi/*[not(self::tei:cell or preceding-sibling::tei:cell)]" />
					</hi>
				</xsl:when>
				<xsl:when test="count(*)=2 and *[1][self::tei:lb] and *[2][self::tei:hi]">
					<xsl:apply-templates select="*[1]" />
					<hi>
						<xsl:apply-templates select="tei:hi/@*" />
						<xsl:apply-templates select="tei:hi/node()[not(self::tei:cell or preceding-sibling::tei:cell)]" />
					</hi>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates />
				</xsl:otherwise>
			</xsl:choose>
		</cell>
		<xsl:apply-templates select="tei:hi/tei:cell" />
	</xsl:template>
	<xsl:template match="tei:cell[ancestor::tei:cell]">
		<cell>
			<xsl:choose>
				<xsl:when test="parent::tei:hi">
					<hi>
						<xsl:apply-templates select="parent::*/@*" />
						<xsl:apply-templates />
					</hi>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates />
				</xsl:otherwise>
			</xsl:choose>
		</cell>
	</xsl:template>
	
	<!-- hoffentlich nur innerhalb eines Wortes. Sonst schwierig -->
	<xsl:template match="tei:w[following-sibling::node()[1][self::tei:unclear]
		and preceding-sibling::node()[1][self::tei:unclear]
		and preceding-sibling::node()[2][not(self::tei:w)]]">
		<w>
			<unclear><xsl:value-of select="preceding-sibling::tei:unclear[1]"/></unclear>
			<xsl:value-of select="."/>
			<unclear><xsl:value-of select="following-sibling::tei:unclear[1]"/></unclear>
		</w>
	</xsl:template>
	<!-- keine Verdoppelung bei XSpec T1.5 -->
	<xsl:template match="tei:w[preceding-sibling::node()[1][self::tei:unclear]
		and preceding-sibling::node()[2][self::tei:w]]" />
	
	<xsl:template match="tei:unclear[preceding-sibling::node()[1][self::tei:w]
		or following-sibling::node()[1][self::tei:w]]" />
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select = "node() | @*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>