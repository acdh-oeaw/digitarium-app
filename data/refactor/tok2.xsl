<xsl:stylesheet xmlns:exist="http://exist.sourceforge.net/NS/exist"
	xmlns="http://www.tei-c.org/ns/1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:wrd="http://github.com/dariok/wienerdiarium"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	exclude-result-prefixes="#all" version="2.0"
	xsi:schemaLocation="http://www.w3.org/1999/XSL/Transform http://www.w3.org/2007/schema-for-xslt20.xsd">
	
	<xsl:template match="tei:TEI">
		<TEI>
			<xsl:sequence select="@*" />
			<xsl:sequence select="tei:teiHeader" />
			<xsl:sequence select="tei:facsimile" />
			<xsl:apply-templates select="tei:text" />
		</TEI>
	</xsl:template>
	
	<xsl:template match="tei:body/tei:div[1]">
		<xsl:choose>
			<xsl:when test="not(tei:title) and tei:head[starts-with(normalize-space(), 'Aus')]">
				<div>
					<xsl:apply-templates select="@*" />
					<xsl:apply-templates select="tei:pb" />
					<xsl:variable name="first" select="(tei:div[tei:head[starts-with(normalize-space(), 'Aus')]])[1]"/>
					<xsl:for-each select="$first/preceding-sibling::tei:div/*[not(self::tei:figure)]">
						<xsl:choose>
							<xsl:when test="self::tei:milestone">
								<xsl:sequence select="." />
							</xsl:when>
							<xsl:otherwise>
								<title>
									<xsl:apply-templates select="@* | node()" />
								</title>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
					<xsl:apply-templates select="$first | $first/following-sibling::*" />
				</div>
			</xsl:when>
			<xsl:otherwise>
				<div>
					<xsl:apply-templates select="@* | *" />
				</div>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:w">
		<xsl:choose>
			<xsl:when test=". = '„'">
				<xsl:choose>
					<xsl:when test="preceding-sibling::*[1][self::tei:lb]
						and preceding-sibling::*[2][wrd:isBreak(.)]"/>
					<xsl:otherwise>
						<pc>„</pc>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<!-- nach Anführungszeichen, Umbruch mit Trennung -->
			<xsl:when test="preceding-sibling::*[1][. = '„']
				and preceding-sibling::*[2][self::tei:lb]
				and preceding-sibling::*[3][wrd:isBreak(.)]" />
			<!-- unmittelbar vor einem Trennzeichen mit Umbruch -->
			<xsl:when test="following-sibling::node()[1][wrd:isBreak(.)]
				and following-sibling::*[2][self::tei:lb]">
				<xsl:choose>
					<xsl:when test="following-sibling::*[3][self::tei:w[matches(., '^[A-Z]')]]">
						<xsl:sequence select=". | following-sibling::*[1]" />
					</xsl:when>
					<xsl:when test="starts-with(normalize-space(following-sibling::*[3]), 'und')">
						<xsl:sequence select=". | following-sibling::*[1]" />
					</xsl:when>
					<xsl:when test="following-sibling::node()[1][self::tei:unclear[matches(node()[1], '\s+')]]">
						<xsl:sequence select="." />
					</xsl:when>
					<xsl:when test="following-sibling::*[3][self::tei:pc[. = '„']] and following-sibling::*[4][self::tei:w]">
						<w>
							<xsl:sequence select="node()"/>
							<xsl:sequence select="following-sibling::*[1] | following-sibling::*[2]" />
							<pc><xsl:sequence select="following-sibling::*[3]/node()"/></pc>
							<xsl:sequence select="following-sibling::*[4]/node()"></xsl:sequence>
						</w>
					</xsl:when>
					<xsl:when test="following-sibling::*[3][self::tei:w]">
						<w>
							<xsl:sequence select="node()"/>
							<xsl:sequence select="following-sibling::*[1] | following-sibling::*[2]" />
							<xsl:sequence select="following-sibling::*[3]/node()"/>
						</w>
					</xsl:when>
					<xsl:when test="following-sibling::*[3][self::tei:gap]">
						<xsl:sequence select=". | following-sibling::*[1]" />
					</xsl:when>
					<xsl:when test="following-sibling::*[3][self::tei:hi]">
						<xsl:choose>
							<xsl:when test="count(following-sibling::tei:hi[1]/tei:w) = 1">
								<xsl:choose>
									<xsl:when test="matches(following-sibling::*[3], '^[a-z]')">
										<w>
											<xsl:value-of select="."/>
											<xsl:sequence select="following-sibling::*[1] | following-sibling::*[2]" />
											<hi>
												<xsl:apply-templates select="following-sibling::tei:hi[1]/@*" />
												<xsl:sequence select="following-sibling::tei:hi[1]/tei:w/node()" />
												<xsl:sequence select="following-sibling::tei:hi[1]/tei:pc" />
											</hi>
										</w>
									</xsl:when>
									<xsl:otherwise>
										<xsl:sequence select=". | following-sibling::*[1]" />
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="following-sibling::*[3][self::tei:unclear]">
						<w>
							<xsl:sequence select="node() | following-sibling::*[1] | following-sibling::*[2]" />
							<unclear><xsl:value-of select="normalize-space(following-sibling::*[3]/tei:w[1])" /></unclear>
						</w>
						<xsl:if test="count(following-sibling::*[3]/tei:w) > 1">
							<xsl:text> </xsl:text>
							<unclear><xsl:sequence select="following-sibling::*[3]/node()[position() > 2
								and not(position() = last())]" />
								<xsl:if test="following-sibling::*[3]/node()[position() = last()][self::tei:w]">
									<xsl:sequence select="following-sibling::*[3]/tei:w[last()]" />
								</xsl:if>
							</unclear>
						</xsl:if>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<!-- unclear mit w zusammengezogen -->
			<xsl:when test="tei:unclear[node()[last()][self::tei:pc[wrd:isBreak(.)]]]
				and following-sibling::*[1][self::tei:lb]
				and following-sibling::*[2][matches(., '^[a-zäöü]') and not (. = 'und')]">
				<xsl:text>
						</xsl:text>
				<w>
					<xsl:sequence select="node() | following-sibling::*[1]" />
						<xsl:sequence select="following-sibling::*[2]/node()" />
				</w>
			</xsl:when>
			<!-- Satzzeichen vor Trennung: unverändert übernehmen -->
			<xsl:when test="preceding-sibling::*[1][self::tei:lb]
				and preceding-sibling::*[2][self::tei:pc[wrd:isBreak(.)]]
				and preceding-sibling::*[3][self::tei:pc or self::tei:gap]">
				<xsl:sequence select="." />
			</xsl:when>
			<!-- unmittelbar nach Umbruch und davor Trennzeichen: wird vorher erledigt -->
			<xsl:when test="preceding-sibling::*[1][self::tei:lb]
				and preceding-sibling::*[2][wrd:isBreak(.) or wrd:isBreak(*[last()])]
				and (matches(., '^[a-zäöü]') and not(. = 'und'))" />
			<!-- unmittelbar hinter hi: wird von hi erledigt -->
			<xsl:when test="preceding-sibling::node()[1][self::tei:hi]" />
			<!-- hinter Umbruch, davor hi mit Trennung -->
			<xsl:when test="preceding-sibling::*[1][self::tei:lb]
				and preceding-sibling::*[2][self::tei:hi or self::tei:unclear]/*[last()][wrd:isBreak(.)]
				and matches(., '^[a-zäöü]')" />
			<xsl:otherwise>
				<xsl:sequence select="." />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:hi">
		<xsl:choose>
			<xsl:when test="preceding-sibling::*[1][self::tei:lb]
				and preceding-sibling::*[2][wrd:isBreak(.)]
				and count(tei:w) = 1
				and matches(., '^[a-z]') and not(. = 'und')"/>
			<xsl:when test="preceding-sibling::*[1][self::tei:lb]
				and preceding-sibling::*[2][self::tei:pc and wrd:isBreak(.)]
				and preceding-sibling::*[3][self::tei:hi]"/>
			<xsl:when test="following-sibling::node()[1][self::tei:w]">
				<xsl:variable name="content">
					<xsl:apply-templates select="node()" />
				</xsl:variable>
				<xsl:if test="count($content/*) > 1">
					<hi>
						<xsl:apply-templates select="@*" />
						<xsl:sequence select="$content/node()[not(position() = last())]" />
					</hi>
				</xsl:if>
				<w>
					<hi>
						<xsl:apply-templates select="@*" />
						<xsl:sequence select="$content/*[position() = last()]/node()" />
					</hi>
					<xsl:sequence select="following-sibling::tei:w[1]/node()" />
				</w>
			</xsl:when>
			<!-- Trennzeichen am Ende nicht markiert als Antiqua -->
			<xsl:when test="following-sibling::node()[1][wrd:isBreak(.)]
				and following-sibling::*[2][self::tei:lb]">
				<xsl:choose>
					<!-- nächste Zeile groß: 2 Wörter -->
					<xsl:when test="following-sibling::*[3][self::tei:w[matches(., '^[A-Z]')]]">
						<xsl:sequence select=". | following-sibling::*[1]" />
					</xsl:when>
					<!-- nächste Zeile kleines w: ein Wort -->
					<xsl:when test="following-sibling::*[3][self::tei:w]">
						<xsl:if test="count(tei:w) > 1">
							<hi>
								<xsl:apply-templates select="@*" />
								<xsl:sequence select="tei:w[following-sibling::*]" />
							</hi>
						</xsl:if>
						<w>
							<hi>
								<xsl:apply-templates select="@*" />
								<xsl:sequence select="tei:w[not(following-sibling::*)]/node()" />
							</hi>
							<xsl:sequence select="following-sibling::*[1] | following-sibling::*[2]" />
							<xsl:sequence select="following-sibling::*[3]/node()" />
						</w>
					</xsl:when>
					<!-- Antiqua am Ende nicht markiert und mit Antiqua weiter -->
					<xsl:when test="count(*) = 1
						and following-sibling::*[1][self::tei:pc[wrd:isBreak(.)]]
						and following-sibling::*[2][self::tei:lb]
						and following-sibling::*[3][self::tei:hi]">
						<w>
							<hi>
								<xsl:apply-templates select="@*" />
								<xsl:value-of select="tei:w"/>
								<xsl:sequence select="following-sibling::*[1] | following-sibling::*[2]" />
								<xsl:value-of select="following-sibling::*[3]" />
							</hi>
							<xsl:value-of select="following-sibling::*[3]/following-sibling::node()[1][self::tei:w]" />
						</w>
					</xsl:when>
					<xsl:when test="following-sibling::*[3][self::tei:hi]">
						<hi>
							<xsl:sequence select="@*" />
							<xsl:sequence select="node()[following-sibling::tei:w]" />
							<w>
								<xsl:value-of select="tei:w[last()]"/>
								<xsl:sequence select="following-sibling::*[1] | following-sibling::*[2]" />
								<xsl:value-of select="following-sibling::*[3]/tei:w[1]"/>
							</w>
							<xsl:sequence select="following-sibling::*[3]/node()[preceding-sibling::tei:w]" />
						</hi>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="following-sibling::node()[1][self::tei:pc[wrd:isBreak(.)]]
				and following-sibling::node()[2][self::tei:w]">
				<xsl:sequence select="." />
			</xsl:when>
			<xsl:when test="*[last()][wrd:isBreak(.)]
				and following-sibling::*[1][self::tei:lb]">
				<xsl:choose>
					<!-- gemischtes Wort -->
					<xsl:when test="following-sibling::*[2][self::tei:w[matches(., '^[a-z]')]]">
						<xsl:if test="count(tei:w) > 1">
							<hi>
								<xsl:sequence select="@* | node()[position() &lt; last() -2]" />
							</hi>
							<xsl:text> </xsl:text>
						</xsl:if>
						<w>
							<hi>
								<xsl:sequence select="@* | tei:w[last()]/node() | tei:pc[last()]"/>
							</hi>
							<xsl:sequence select="following-sibling::*[1] | following-sibling::*[2]/node()" />
						</w>
					</xsl:when>
					<xsl:when test="following-sibling::*[2][self::tei:w]">
						<xsl:sequence select="." />
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<xsl:apply-templates select="@* | node()"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:pc">
		<xsl:choose>
			<xsl:when test=". = '„' and preceding-sibling::*[1][self::tei:lb]" />
			<xsl:when test="following-sibling::*[1][self::tei:w[matches(., '^[A-Z]')]]">
				<xsl:sequence select="." />
			</xsl:when>
			<xsl:when test="wrd:isBreak(.)
				and following-sibling::*[1][self::tei:lb]
				and preceding-sibling::*[1][self::tei:w or tei:w]" />
			<xsl:otherwise>
				<xsl:sequence select="." />
			</xsl:otherwise>
		</xsl:choose>	
	</xsl:template>
	
	<xsl:template match="text()[preceding-sibling::*[1][self::tei:pc]
		and following-sibling::*[1][self::tei:lb]]" />
	
	<!-- unclear direkt vor oder nach w: Template für w nimmt sich, was es braucht, der Rest wird hier ausgegeben -->
	<xsl:template match="tei:unclear[count(*) > 1
		and not(*[last()][self::tei:pc[wrd:isBreak(.)]])
		and preceding-sibling::node()[1][self::tei:w]]">
		<unclear>
			<xsl:sequence select="node()[preceding-sibling::tei:w]" />
		</unclear>
	</xsl:template>
	<xsl:template match="tei:unclear[count(*) > 1
		and tei:w
		and following-sibling::node()[1][self::tei:w]]">
		<unclear>
			<xsl:sequence select="node()[following-sibling::tei:w]" />
		</unclear>
	</xsl:template>
	<xsl:template match="tei:unclear[count(*) = 1
		and tei:w
		and (preceding-sibling::node()[1][self::tei:w] or following-sibling::node()[1][self::tei:w])]" />
	<xsl:template match="tei:unclear[preceding-sibling::*[1][self::tei:lb]
		and preceding-sibling::*[2][self::tei:pc[wrd:isBreak(.)]]]" />
	
	<xsl:template match="tei:unclear[*[last()][self::tei:pc[wrd:isBreak(.)]]
		and following-sibling::*[1][self::tei:lb]
		and following-sibling::*[2][self::tei:w[matches(., '^[a-z]')]]]">
		<xsl:if test="count(tei:w) > 1">
			<unclear>
				<xsl:sequence select="node()[following-sibling::tei:w]" />
			</unclear>
		</xsl:if>
		<w>
			<unclear>
				<xsl:value-of select="normalize-space(tei:w[not(following-sibling::tei:w)])"/>
				<xsl:sequence select="tei:pc" />
			</unclear>
			<xsl:sequence select="following-sibling::*[1]" />
			<xsl:sequence select="following-sibling::*[2]/node()"/>
		</w>
	</xsl:template>
	<xsl:template match="tei:unclear[
		following-sibling::*[1][self::tei:pc[wrd:isBreak(.)]]
		and following-sibling::*[2][self::tei:lb]
		and following-sibling::*[3][self::tei:w]]">
		<xsl:if test="count(tei:w) > 1">
			<unclear>
				<xsl:sequence select="node()[following-sibling::tei:w]" />
			</unclear>
		</xsl:if>
		<w>
			<unclear><xsl:value-of select="tei:w[last()]"/></unclear>
			<xsl:sequence select="following-sibling::*[position() &lt; 3]" />
			<xsl:value-of select="following-sibling::*[3]"/>
		</w>
	</xsl:template>
	
	<xsl:template match="tei:lb">
		<xsl:choose>
			<xsl:when test="preceding-sibling::*[1][
				(wrd:isBreak(.) and not(preceding-sibling::*[1][self::tei:pc]))
				or self::tei:w[*[wrd:isBreak(.)]]
				or self::tei:unclear[*[wrd:isBreak(.)]]]
			and not(preceding-sibling::*[2][self::tei:gap])
			and following-sibling::*[1][matches(normalize-space(), '^[a-zäüö]')
				and not(starts-with(normalize-space(), 'und'))]"/>
			<xsl:when test="following-sibling::*[1][. = '„'] and preceding-sibling::*[1][wrd:isBreak(.)]" />
			<xsl:otherwise>
				<xsl:text>
						</xsl:text>
				<xsl:sequence select="." />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:function name="wrd:isBreak" as="xs:boolean">
		<xsl:param name="context" />
		<xsl:choose>
			<xsl:when test="$context/self::tei:pc">
				<xsl:sequence select="if($context='-' or $context='=') then true() else false()" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="if($context/*[last()][self::tei:pc[.='-' or .='=']]) then true() else false()" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:template match="text()">
		<xsl:choose>
			<xsl:when test="normalize-space() = ''
				and following-sibling::node()[1][self::tei:pc[.=(',', '.', ':', ';')]]
				or (preceding-sibling::*[1][wrd:isBreak(.) or *[wrd:isBreak(.)]]
					and following-sibling::*[1][self::tei:lb])"/>
			<!-- hinter „ und Umbruch mit Trennung -->
			<xsl:when test="preceding-sibling::node()[1][. = '„']
				and preceding-sibling::*[2][self::tei:lb]
				and preceding-sibling::*[3][wrd:isBreak(.)]" />
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="* | @*">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>