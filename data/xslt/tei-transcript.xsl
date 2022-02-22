<xsl:stylesheet xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:mets="http://www.loc.gov/METS/" xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="." xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	exclude-result-prefixes="#all" version="3.0">
	
	<!-- Bearbeiter für Wiener Diarium ab 2017-04-01 DK: Dario Kampkaspar, dario.kampkaspar@oeaw.ac.at -->
	<xsl:param name="xml" as="xs:string"/>
	<xsl:param name="xsl" as="xs:string"/>
	
	<!-- Imports werden über tei-common abgewickelt; 2015/10/23 DK -->
	<xsl:import href="tei-common.xsl#1"/>
	
	<!-- angepaßt für Diarium; 2017-10-05 DK -->
	<xsl:template match="/">
		<xsl:apply-templates select="//tei:div[@type='page'] | //tei:front"/>
		<footer>
			<span>XML: <a href="{$xml}" target="_blank"><xsl:value-of select="$xml" /></a></span>
			<span>XSL: <a href="{$xsl}" target="_blank"><xsl:value-of select="$xsl" /></a></span>
		</footer>
	</xsl:template>
	
	<xsl:template match="tei:front">
		<div class="page">
			<xsl:apply-templates select="tei:titlePage/tei:pb" />
			<div class="pageHeader">
				<xsl:apply-templates select="tei:titlePage/tei:*[not(self::tei:pb)]"/>
			</div>
		</div>
	</xsl:template>
	<xsl:template match="tei:titlePart">
		<xsl:variable name="name">
			<xsl:choose>
				<xsl:when test="@type='main'">h1</xsl:when>
				<xsl:when test="@type='motto'">p</xsl:when>
				<xsl:otherwise>h2</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:element name="{$name}">
			<xsl:attribute name="class">
				<xsl:if test="not(@type = 'motto')">
					<xsl:text>title </xsl:text>
				</xsl:if>
				<xsl:value-of select="substring-after(@rendition, '#')" />
			</xsl:attribute>
			<xsl:apply-templates />
		</xsl:element>
	</xsl:template>
	<xsl:template match="tei:imprimatur">
		<p class="title imprimatur {substring-after(@rendition, '#')}">
			<xsl:apply-templates />
		</p>
	</xsl:template>
	<xsl:template match="tei:docTitle">
		<xsl:for-each-group select="tei:*" group-starting-with="tei:*[local:isFirst(.)]">
			<xsl:variable name="class">
				<xsl:choose>
					<xsl:when test="local:isLR(current-group()[1], '#l')">triL</xsl:when>
					<xsl:when test="local:isLR(current-group()[1], '#r')">triR</xsl:when>
					<xsl:when test="local:isLR(current-group()[1], '#c')">triC</xsl:when>
					<xsl:otherwise>triF</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<div class="{$class}">
				<xsl:apply-templates select="current-group()" />
			</div>
		</xsl:for-each-group>
	</xsl:template>

	<!-- Body-Elemente -->
	<xsl:template match="tei:div[@type='page']">
		<div class="page">
			<xsl:variable name="cb" select="descendant::tei:cb"/>
			<xsl:apply-templates select="tei:pb" />
			<div class="pageHeader">
				<xsl:apply-templates select="tei:fw[not(preceding-sibling::tei:div)]" />
			</div>
			
			<xsl:variable name="divs">
				<xsl:apply-templates select="tei:div/tei:*[local:isFirst(.)]" mode="group">
					<xsl:with-param name="cb" select="$cb" />
				</xsl:apply-templates>
			</xsl:variable>
			<xsl:for-each-group select="$divs/*" group-starting-with="div[@class = 'divL' or @class= 'divF']
				[not(preceding-sibling::*[1][@class = 'divL' or @class='divF'])]">
				<div>
					<xsl:attribute name="class">
						<xsl:choose>
							<xsl:when test="current-group()[@class = 'divC' or @class = 'divC cb']">divLCR</xsl:when>
							<xsl:when test="current-group()[@class = 'divR' or @class = 'divR cb']">divLR</xsl:when>
							<xsl:otherwise>divLF</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:sequence select="current-group()" />
				</div>
			</xsl:for-each-group>
			
			<div class="pageFooter">
				<xsl:if test="not(tei:fw[not(following-sibling::tei:div) and starts-with(@rendition, '#l')])">
					<span class="triL" />
				</xsl:if>
				<xsl:if test="not(tei:fw[not(following-sibling::tei:div) and starts-with(@rendition, '#c')])">
					<span class="triC" />
				</xsl:if>
				<xsl:apply-templates select="tei:fw[not(following-sibling::tei:div)]" />
			</div>
		</div>
	</xsl:template>
	<xsl:template match="tei:*" mode="group">
		<xsl:param name="cb" />
		<xsl:variable name="myid" select="generate-id()" />
		<xsl:variable name="myloc" select="substring(@rendition, 2, 1)"/>
		<xsl:variable name="foll" select="following-sibling::*[substring(@rendition, 2, 1) != $myloc][1]"/>
		<div>
			<xsl:attribute name="class">
				<xsl:value-of select="'div' || upper-case($myloc)"/>
				<xsl:if test="$cb and not($myloc = 'l' or $myloc = 'f') and not(self::tei:fw or self::tei:milestone)">
					<xsl:text> cb</xsl:text>
				</xsl:if>
			</xsl:attribute>
			<xsl:apply-templates select=".
				| (if (count($foll) = 1)
						then following-sibling::* intersect $foll/preceding-sibling::*
						else (following-sibling::*,
							parent::tei:div/following-sibling::tei:div/*[substring(@rendition, 2, 1) = $myloc
								and $myid = generate-id(preceding::tei:*[local:isContent(.) and local:isFirst(.)][1])]))" />
		</div>
	</xsl:template>
	
	<!-- neu 2017-10-03 DK -->
	<xsl:template match="tei:fw">
		<xsl:variable name="myloc" select="if(@rendition) then substring(@rendition, 2, 1)
			else substring(*[1]/@rendition, 2, 1)"/>
		<span>
			<xsl:apply-templates select="@xml:id" />
			<xsl:attribute name="class">
				<xsl:value-of select="'tri' || upper-case($myloc)"/>
				<xsl:if test="@type">
					<xsl:value-of select="' ' || translate(@type, '.', ' ')"/>
				</xsl:if>
				<xsl:if test="tei:figure or tei:graphic">
					<xsl:text> image</xsl:text>
				</xsl:if>
			</xsl:attribute>
			<xsl:choose>
				<xsl:when test="tei:milestone or $myloc = 'l'">
					<xsl:apply-templates />
				</xsl:when>
				<xsl:otherwise>
					<span>
						<xsl:attribute name="class">
							<xsl:value-of select="'fw ' || substring-after(@rendition, '#')"/>
							<xsl:if test="@type = 'main'">
								<xsl:text> main</xsl:text>
							</xsl:if>
						</xsl:attribute>
						<xsl:apply-templates/>
					</span>
				</xsl:otherwise>
			</xsl:choose>
		</span>
	</xsl:template>
	
	<xsl:template match="tei:figure" />
	
	<!-- neu 2017-10-03 DK -->
	<xsl:template match="tei:milestone[@type = 'separator' and @rend = 'horizontal']">
		<hr class="{substring-after(@rendition, '#')}"/>
	</xsl:template>

	<!-- h3 für die wichtigsten Überschriften, sonst h4; vgl. #133 -->
	<xsl:template match="tei:head">
		<xsl:variable name="name">
			<xsl:choose>
				<!--<xsl:when test="contains(., 'Lista') or contains(., 'Ankunft') or contains(., 'Ankunfft')
					or starts-with(normalize-space(), 'Aus') or starts-with(normalize-space(), 'Avertissement')">h3</xsl:when>
				<xsl:when test="contains(., 'Den') or contains(., 'den') or matches(., '.+\s*\d+.+')">h4</xsl:when>
				<xsl:when test="following-sibling::*[1][self::tei:list]">h4</xsl:when>
				<xsl:when test="parent::tei:div[not(@type)]">h3</xsl:when>-->
				<xsl:when test="contains(., 'Lista') or contains(., 'Ankunft') or contains(., 'Ankunfft')
					or starts-with(normalize-space(), 'Avertissement')">h3</xsl:when>
				<xsl:otherwise>h4</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="contains(@rend, 'dist')">
			<br/>
		</xsl:if>
		<xsl:element name="{$name}">
			<xsl:apply-templates select="@xml:id | @rendition" />
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:w/tei:hi">
		<span>
			<xsl:attribute name="class">
				<xsl:text>w</xsl:text>
				<xsl:if test="@style = 'font-family: Antiqua;'">
					<xsl:text> italic</xsl:text>
				</xsl:if>
				<xsl:if test="@rend = 'super'">
					<xsl:text> superscript</xsl:text>
				</xsl:if>
				<xsl:if test="@rend = 'sub'">
					<xsl:text> subscript</xsl:text>
				</xsl:if>
				<xsl:if test="parent::tei:p">
					<xsl:text> inlineHead</xsl:text>
				</xsl:if>
			</xsl:attribute>
			<xsl:apply-templates />
		</span>
	</xsl:template>

	<!-- tei:hi ausgelagert nach common; 2016-05-27 DK -->

	<!-- @style kommt nicht vor; 2016-05-30 DK -->
	<xsl:template match="tei:p">
		<xsl:if test="contains(@rend, 'dist')">
			<br/>
		</xsl:if>
		<p id="{@xml:id}">
			<xsl:attribute name="class">
				<xsl:text>content </xsl:text>
				<xsl:value-of select="substring-after(@rendition, '#')"/>
				<xsl:if test="not(matches(descendant::tei:w[1], '^[A-ZÄÖÜ0-9]'))">
					<xsl:text> noindent</xsl:text>
				</xsl:if>
				<xsl:value-of select="' ' || @rend"/>
			</xsl:attribute>
			<xsl:apply-templates/>
		</p>
	</xsl:template>

	<xsl:template match="tei:pb">
		<div class="pagebreak" id="{@xml:id}">
			<span class="pageNavL">
				<xsl:text>‖ </xsl:text>
			</span>
			<span class="pageNav">
				<xsl:if test="preceding::tei:pb">
					<xsl:variable name="pf" select="substring-after(preceding::tei:pb[1]/@facs, '#')"/>
					<a
						href="https://diarium-exist.acdh-dev.oeaw.ac.at/exist/restxq/edoc/resource/iiif/{/tei:TEI/@xml:id}/{$pf}.json">
						<xsl:text>← </xsl:text>
					</a>
				</xsl:if>
			</span>
			<span class="pb">
				<xsl:text>[</xsl:text>
				<a>
					<xsl:attribute name="href">
						<xsl:text>https://diarium-exist.acdh-dev.oeaw.ac.at/exist/restxq/edoc/resource/iiif/</xsl:text>
						<xsl:value-of select="/tei:TEI/@xml:id"/>
						<xsl:text>/</xsl:text>
						<xsl:value-of select="substring-after(@facs, '#')"/>
						<xsl:text>.json</xsl:text>
					</xsl:attribute>
					<xsl:value-of select="@n"/>
				</a>
				<xsl:text>]</xsl:text>
			</span>
			<span class="pageNav">
				<xsl:if test="following::tei:pb">
					<xsl:variable name="ff" select="substring-after(following::tei:pb[1]/@facs, '#')"/>
					<a
						href="https://diarium-exist.acdh-dev.oeaw.ac.at/exist/restxq/edoc/resource/iiif/{/tei:TEI/@xml:id}/{$ff}.json">
						<xsl:text> →</xsl:text>
					</a>
				</xsl:if>
			</span>
			<span class="pageNavR">
				<xsl:text> ‖</xsl:text>
			</span>
		</div>
	</xsl:template>
	
	<!-- nur ab dem 2. lb; 2017-10-05 DK -->
	<xsl:template match="tei:lb">
		<!-- Zur Hervohebung der Zeile -->
		<span class="invisible" data-rect="{id(substring-after(@facs, '#'))/@points}"/>
		<xsl:if test="
			(preceding-sibling::tei:* or ancestor::tei:w or ancestor::tei:hi or ancestor::tei:quote
				or preceding-sibling::tei:quote[tei:lb])
			and not(preceding-sibling::*[1][self::tei:milestone])">
			<br>
				<xsl:attribute name="data-rect" select="id(substring-after(@facs, '#'))/@points" />
			</br>
		</xsl:if>
	</xsl:template>
	
	<!-- neu 2018-08-06 DK -->
	<xsl:template match="tei:choice">
		<xsl:apply-templates select="tei:orig | tei:sic" />
	</xsl:template>
	
	<!-- allgem. Listen; 2017-10-31 DK -->
	<xsl:template match="tei:list">
		<xsl:apply-templates select="tei:head" />
		<ul class="{substring-after(@rendition, '#')}">
			<xsl:apply-templates select="@xml:id" />
			<xsl:apply-templates select="tei:item"/>
		</ul>
	</xsl:template>
	<xsl:template match="tei:item">
		<li id="{@xml:id}">
			<xsl:choose>
				<xsl:when test="@rendition = '#fi'">
					<xsl:attribute name="class">findent</xsl:attribute>
				</xsl:when>
				<xsl:when test="@rend">
					<xsl:attribute name="class"><xsl:value-of select="@rend"/></xsl:attribute>
				</xsl:when>
				<xsl:when test="parent::tei:list[@rend='findent']">
					<xsl:attribute name="class">findent</xsl:attribute>
				</xsl:when>
			</xsl:choose>
            <xsl:apply-templates/>
        </li>
	</xsl:template>
	<!-- ENDE Listen -->
	
	<!-- neu 2017-05-05 DK -->
	<xsl:template match="tei:w">
		<span id="{@xml:id}">
		    <xsl:attribute name="class">
		    	<xsl:text>w</xsl:text>
		    	<xsl:if test="parent::tei:hi[contains(@style, 'Antiqua')]">
		    		<xsl:text> italic</xsl:text>
		    	</xsl:if>
		    	<xsl:if test="parent::tei:hi[@rend = 'super']">
		    		<xsl:text> superscript</xsl:text>
		    	</xsl:if>
		    	<xsl:if test="parent::tei:hi[@rend = 'sub']">
		    		<xsl:text> subscript</xsl:text>
		    	</xsl:if>
		    	<xsl:if test="ancestor::tei:label[parent::tei:p]">
		    		<xsl:text> inlineHead</xsl:text>
		    	</xsl:if>
		    </xsl:attribute>
			<xsl:if test="@style">
				<xsl:attribute name="style" select="@style"/>
			</xsl:if>
			<xsl:attribute name="title">
				<xsl:value-of select="xs:string(@xml:id) || ': '" />
				<xsl:choose>
					<xsl:when test="tei:choice">
						<xsl:value-of select="tei:choice/tei:sic | tei:choice/tei:orig" />
						<xsl:text> (</xsl:text>
						<xsl:value-of select="tei:choice/tei:corr | tei:choice/tei:reg" />
						<xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates/>
		</span>
	</xsl:template>
	
	<!-- neu 2017-10-16 DK -->
	<xsl:template match="tei:pc">
		<span id="{@xml:id}" class="pc">
			<xsl:attribute name="class">
				<xsl:text>pc</xsl:text>
				<xsl:if test="parent::tei:hi[contains(@style, 'Antiqua')]">
					<xsl:text> italic</xsl:text>
				</xsl:if>
				<!-- im Fall Nro. mit ro, hochgestellt muß sonst doppeltes hi verwendet werden -->
				<xsl:if test="parent::tei:hi[@rend = 'super'] and not(ancestor::tei:w)">
					<xsl:text> superscript</xsl:text>
				</xsl:if>
				<xsl:if test="parent::tei:hi[@rend = 'sub']">
					<xsl:text> subscript</xsl:text>
				</xsl:if>
				<xsl:if test="ancestor::tei:label[parent::tei:p]">
					<xsl:text> inlineHead</xsl:text>
				</xsl:if>
			</xsl:attribute>
			<xsl:apply-templates/>
		</span>
	</xsl:template>
	
	<xsl:template match="tei:label">
		<span>
			<xsl:attribute name="class">
				<xsl:value-of select="string-join(('label', substring-after(@rendition, '#'), @rend), ' ')"/>
			</xsl:attribute>
			<xsl:apply-templates />
		</span>
	</xsl:template>
	
	<!-- Leerzeichen am Zeilenende vermeiden; 2017-10-31 DK -->
	<xsl:template match="text()[normalize-space() = '' and following-sibling::*[1][self::tei:lb]]"/>
	
	<!-- Gedichte etc.; übernommen aus dariok/rist -->
	<xsl:template match="tei:lg">
		<p class="lg">
			<xsl:if test="@style">
				<xsl:attribute name="style" select="@style" />
			</xsl:if>
			<xsl:apply-templates select="tei:label"/>
			<span class="ls">
				<xsl:apply-templates select="tei:l | tei:pb" />
			</span>
		</p>
	</xsl:template>
	<xsl:template match="tei:l">
		<span>
			<xsl:if test="parent::tei:lg/@rend">
				<xsl:attribute name="style">
					<xsl:text>padding-left:</xsl:text>
					<xsl:call-template name="m"/>
					<xsl:text>em;</xsl:text>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
			<br/>
		</span>
	</xsl:template>
	<xsl:template name="m">
		<xsl:variable name="f" select="tokenize(parent::tei:lg/@rend, ',')" />
		<xsl:variable name="fc" select="count($f)" />
		<xsl:variable name="po" select="count(preceding-sibling::tei:l)+1"/>
		<xsl:variable name="rp" select="$po mod $fc" />
		<xsl:variable name="t" select="if ($rp != 0) then $rp else $fc"/>
		<xsl:value-of select="$f[$t]" />
	</xsl:template>
	<xsl:template match="tei:lg/tei:label">
		<label><xsl:apply-templates/></label><br/>
	</xsl:template>
	
	<!-- FUNCTIONS -->
	<xsl:function name="local:hasFullWidth" as="xs:boolean">
		<xsl:param name="context"/>
		<xsl:value-of select="if($context/@rendition)
				then starts-with($context/@rendition, '#f')
				else $context/tei:*[starts-with(@rendition, '#f')] " />
	</xsl:function>
	<xsl:function name="local:isLR" as="xs:boolean">
		<xsl:param name="context" />
		<xsl:param name="lr" as="xs:string" />
		<xsl:value-of select="if($context/@rendition)
			then starts-with($context/@rendition, $lr)
			else if($context/tei:*[starts-with(@rendition, $lr)]) then true() else false()"/>
	</xsl:function>
	
	<xsl:function name="local:isContent" as="xs:boolean">
		<xsl:param name="context" />
		<xsl:value-of select="not($context/self::tei:div) and $context/parent::tei:div[not(@type = 'page')]"/>
	</xsl:function>
	
	<xsl:function name="local:isFirst" as="xs:boolean">
		<xsl:param name="context" />
		<xsl:variable name="orientation" select="substring($context/@rendition, 1, 2)" />

		<xsl:variable name="prec" select="if ($context/preceding-sibling::*)
			then $context/preceding-sibling::tei:*[1]
			else $context/parent::tei:div/preceding-sibling::tei:div[1]/tei:*[last()]" />
		<xsl:variable select="not(starts-with($prec/@rendition, $orientation))" name="val"/>
		<xsl:value-of select="$val" />
	</xsl:function>
	
	<xsl:template match="@xml:id">
		<xsl:attribute name="id" select="."/>
	</xsl:template>
	
	<xsl:template match="@rendition">
		<xsl:attribute name="class" select="translate(., '#', '')"/>
	</xsl:template>
</xsl:stylesheet>
