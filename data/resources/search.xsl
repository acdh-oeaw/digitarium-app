<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="#all" version="3.0">
	
	<xsl:param name="title"/>
	<xsl:param name="rest"/>
	
	<xsl:template match="/results">
		<xsl:variable name="val">, "job": "fts"</xsl:variable>
		<div>
			<xsl:choose>
				<xsl:when test="@count &gt; 0">
					<h1>Suchergebnisse für »<xsl:value-of select="@q"/>«</h1>
					<xsl:if test="@count &gt; 25 and (@from != '' and @from &gt; 1)">
						<xsl:variable name="f1">{"start": 1<xsl:value-of select="$val"/>}</xsl:variable>
						<xsl:variable name="f2">{"start": <xsl:value-of select="if(@from &gt; 25) then @from - 25 else 1"/>
							<xsl:value-of select="$val"/>}</xsl:variable>
						<a href="search.html?id={@id}&amp;q={@q}&amp;p={encode-for-uri($f1)}">[1]</a>
						<a href="search.html?id={@id}&amp;q={@q}&amp;p={encode-for-uri($f2)}">[<xsl:value-of select="@from - 25"/>–<xsl:value-of select="@from - 1"/>]</a>
					</xsl:if>
					<span>
						<xsl:text> – Treffer </xsl:text>
						<xsl:value-of select="@from"/>
						<xsl:text> bis </xsl:text>
						<xsl:value-of select="if(@from + 25 &gt; @count) then @count else @from + 25"/>
						<xsl:text> von insgesamt </xsl:text>
						<xsl:value-of select="@count"/>
						<xsl:text> Ausgaben – </xsl:text>
					</span>
					<xsl:if test="@count &gt; 25 and @from + 25 &lt; @count">
						<xsl:variable name="f1">{"start": <xsl:value-of select="@from + 25"/>
							<xsl:value-of select="$val"/>}</xsl:variable>
						<xsl:variable name="f2">{"start": <xsl:value-of select="@count - 24"/>
							<xsl:value-of select="$val"/>}</xsl:variable>
						<a href="search.html?id={@id}&amp;q={@q}&amp;p={encode-for-uri($f1)}">
							<xsl:text>[</xsl:text>
							<xsl:value-of select="@from + 25"/>
							<xsl:text>–</xsl:text>
							<xsl:value-of select="if(@from + 49 &lt; @count) then @from + 49 else @count"/>
							<xsl:text>]</xsl:text>
						</a>
						<a href="search.html?id={@id}&amp;q={@q}&amp;p={encode-for-uri($f2)}">[Ende]</a>
					</xsl:if>
					<ul>
						<xsl:apply-templates/>
					</ul>
				</xsl:when>
				<xsl:otherwise>
					<h1>Keine Ergebnisse für »<xsl:value-of select="@q"/>«</h1>
					<p>Bitte versuchen Sie eine andere Anfrage!</p>
				</xsl:otherwise>
			</xsl:choose>
		</div>
	</xsl:template>
	
	<xsl:template match="file">
		<li>
			<a href="view.html?id={@id}">
				<xsl:value-of select="*:title[@type = 'num']"/>
			</a>
			<a href="javascript:void(0);" onclick="load('{$rest}search/file/{@id}.html?q={ancestor::results/@q}', '{@id}', this)">
				<xsl:apply-templates select="tei:titleStmt" />
				<xsl:text> →</xsl:text></a>
			<div id="{@id}" class="results" style="display: none;"/>
		</li>
	</xsl:template>
	
	<xsl:template match="result">
		<xsl:variable name="ids" select="descendant::*:match/ancestor::*[@xml:id][1]/@xml:id"/>
		<xsl:variable name="i" select="string-join($ids, ',')"/>
		<li>
			<a href="view.html?id={parent::results/@id}&amp;i={$i}#{@fragment}">
				<xsl:apply-templates select="@fragment"/>
			</a>
			<xsl:value-of select="' (' || count(*) || ' Treffer)'"/>
			<a href="javascript:void(0);" onclick="$('#{parent::results/@id}{@fragment}').toggle();"> →</a>
			<div id="{parent::results/@id}{@fragment}" class="results" style="display: none;">
				<xsl:apply-templates select="match"/>
			</div>
		</li>
	</xsl:template>
	<xsl:template match="@fragment">
		<xsl:variable name="values" select="analyze-string(., '\d+')" />
		<xsl:choose>
			<xsl:when test="$values/*:non-match = 'p'">Absatz</xsl:when>
			<xsl:when test="$values/*:non-match = 'hl'">Überschrift</xsl:when>
			<xsl:when test="$values/*:non-match = 'i'">Listeneintrag</xsl:when>
			<xsl:when test="$values/*:non-match = 'c'">Tabelleneintrag</xsl:when>
		</xsl:choose>
		<xsl:text> </xsl:text>
		<xsl:value-of select="$values/*:match"/>
	</xsl:template>
	
	<xsl:template match="match">
		<p>
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	
	<xsl:template match="tei:titleStmt">
		<xsl:value-of select="tei:title[@type = 'num']"/>
	</xsl:template>
	
	<xsl:template match="tei:w | tei:pc">
		<xsl:choose>
			<xsl:when test="*:match">
				<span class="match">
					<xsl:apply-templates/>
				</span>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="not(following-sibling::*[1][self::tei:pc][matches(., '[.,!?]')])">
			<xsl:text> </xsl:text>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>