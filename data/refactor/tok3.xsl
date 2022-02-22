<xsl:stylesheet xmlns:exist="http://exist.sourceforge.net/NS/exist"
	xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	exclude-result-prefixes="#all" version="2.0"
	xsi:schemaLocation="http://www.w3.org/1999/XSL/Transform http://www.w3.org/2007/schema-for-xslt20.xsd">
	
<!--	<xsl:output indent="yes" />-->
	
	<xsl:template match="/tei:TEI">
		<TEI>
			<xsl:apply-templates select="* | @*"/>
		</TEI>
	</xsl:template>
	
	<xsl:template match="tei:text">
		<xsl:variable name="last" select="tei:body/tei:div[1]/tei:title[not(following-sibling::tei:title)]"/>
		
		<text>
			<xsl:choose>
				<xsl:when test="count($last) = 1">
					<front>
						<titlePage>
							<xsl:apply-templates select="$last/preceding-sibling::* | $last" />
						</titlePage>
					</front>
					<body>
						<xsl:if test="$last/following-sibling::*">
							<div type="page" n="1">
								<xsl:apply-templates select="$last/following-sibling::*" />
							</div>
						</xsl:if>
						<xsl:apply-templates select="tei:body/tei:div[position() &gt; 1]" />
					</body>
				</xsl:when>
				<xsl:otherwise>
					<body>
						<xsl:apply-templates select="tei:body/tei:div" />
					</body>
				</xsl:otherwise>
			</xsl:choose>
		</text>
	</xsl:template>
	<xsl:template match="tei:text//tei:title">
		<xsl:choose>
			<xsl:when test="matches(., '[pP]rivilegio') or matches(., 'Fre[iy]heit')">
				<imprimatur facs="{@facs}" rendition="{@rendition}">
					<xsl:apply-templates />
				</imprimatur>
			</xsl:when>
			<xsl:when test="matches(., 'Num')">
				<docTitle>
					<titlePart type="num" facs="{@facs}" rendition="{@rendition}">
						<xsl:apply-templates />
					</titlePart>
				</docTitle>
			</xsl:when>
			<xsl:when test="matches(., 'Wienn?er')">
				<docTitle>
					<titlePart type="main" facs="{@facs}" rendition="{@rendition}">
						<xsl:apply-templates />
					</titlePart>
				</docTitle>
			</xsl:when>
			<xsl:otherwise>
				<docTitle>
					<titlePart facs="{@facs}" rendition="{@rendition}">
						<xsl:apply-templates />
					</titlePart>
				</docTitle>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:w">
		<w>
			<xsl:attribute name="xml:id">
				<xsl:text>w</xsl:text>
				<xsl:number count="tei:w | tei:pc" level="any"/>
			</xsl:attribute>
			<xsl:apply-templates />
		</w>
	</xsl:template>
	
	<xsl:template match="tei:pc">
		<pc>
			<xsl:attribute name="xml:id">
				<xsl:text>w</xsl:text>
				<xsl:number count="tei:w | tei:pc" level="any"/>
			</xsl:attribute>
			<xsl:apply-templates />
		</pc>
	</xsl:template>
	
	<!-- aus Zusammensetzung bei Zeilenumbruch in tok2 -->
<!--	<xsl:template match="tei:unclear[ancestor::tei:w]">
		<unclear>
			<xsl:apply-templates select="@*" />
			<xsl:value-of select="."/>
		</unclear>
	</xsl:template>-->
	
	<!-- Doppelungen vermeiden -->
	<xsl:template match="tei:unclear[tei:unclear]">
		<unclear><xsl:value-of select="."/></unclear>
	</xsl:template>
	
	<xsl:template match="tei:w[ancestor::tei:w]">
		<xsl:value-of select="."/>
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