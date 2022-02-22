<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta" exclude-result-prefixes="#all" version="3.0">
	
	<xsl:param name="id"/>
	
	<xsl:template match="/">
		<ul>
			<xsl:apply-templates select="meta:struct">
				<xsl:sort select="number(@order)"></xsl:sort>
			</xsl:apply-templates>
		</ul>
	</xsl:template>
	
	<xsl:template match="meta:struct[descendant::meta:view]">
		<xsl:variable name="file" select="if (@file) then @file else parent::*/@file"/>
		<xsl:variable name="ln">
			<xsl:value-of select="$file" />
			<xsl:choose>
				<xsl:when test="meta:view">
					<xsl:value-of select="@order" />
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<li id="{$ln}">
			<xsl:variable name="hidden" select="parent::meta:struct and not(@file = $id     or descendant::meta:struct[@file = $id]     or ancestor::meta:struct[@file= $id]     or parent::meta:struct/meta:struct[@file = $id])"/>
			<xsl:if test="$hidden">
				<xsl:attribute name="style">display: none;</xsl:attribute>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="parent::meta:struct and meta:view">
					<a href="javascript: void(0);" onclick="switchnav({$ln}, this);">
						<!--<xsl:choose>
    						<xsl:when test="meta:view[@file = $id]">↑</xsl:when>
    						<xsl:otherwise>→</xsl:otherwise>
    					</xsl:choose>-->
						<xsl:text>↑</xsl:text>
					</a>
					<xsl:text> </xsl:text>
					<span class="month">
						<xsl:value-of select="@label"/>
					</span>
				</xsl:when>
				<xsl:otherwise>
					<a href="javascript: void(0);" onclick="switchnav({$file}, this);">
						<xsl:choose>
							<xsl:when test="descendant::meta:struct[@file = $id] or @file = $id">↑</xsl:when>
							<xsl:otherwise>→</xsl:otherwise>
						</xsl:choose>
					</a>
					<xsl:text> </xsl:text>
					<a href="start.html?id={$file}">
						<xsl:value-of select="@label"/>
					</a>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="meta:struct or meta:view">
				<ul>
					<xsl:apply-templates/>
				</ul>
			</xsl:if>
		</li>
	</xsl:template>
	
	<xsl:template match="meta:view">
		<li>
			<a href="view.html?id={@file}">
				<xsl:value-of select="@label"/>
			</a>
		</li>
	</xsl:template>
	
	<xsl:template match="*:user"/>
</xsl:stylesheet>