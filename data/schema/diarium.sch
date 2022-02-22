<schema xmlns="http://purl.oclc.org/dsdl/schematron"
	xmlns:sqf="http://www.schematron-quickfix.com/validator/process" queryBinding="xslt2">

	<ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>

	<pattern id="rendition">
		<rule context="tei:text//tei:*">
			<report test="not(self::tei:cb) and (parent::tei:div[not(@type = 'page')] or self::tei:fw or (self::tei:milestone and not(parent::tei:*/@rendition))) and not(@rendition)"
				sqf:fix="add-rendition">
				Content muß @rendition haben!
			</report>
			<sqf:fix id="add-rendition">
				<sqf:description>
					<sqf:title>@rendition vom ersten Kind übernehmen</sqf:title>
				</sqf:description>
				<sqf:add match="." select="normalize-space(*[1]/@rendition)" target="rendition" node-type="attribute" />
			</sqf:fix>
			<let name="rends" value="tokenize(@rendition, ' ')" />
			<report test="@rendition and not(every $rend in $rends satisfies $rend =
				('#l', '#lc', '#lr', '#lh', '#c', '#cl', '#cc', '#cr', '#ch', '#r', '#rc', '#rr', '#rh', '#f', '#fc', '#fr',
				'#fh', '#border-top'))"
				> Wert von @rendition ist ungültig </report>
			<report
				test="not(self::tei:fw or self::tei:titlePart) and contains(@rendition, '#c')
					and not(following-sibling::*[contains(@rendition, '#r')])">
					mittlere Spalte (<value-of select="@rendition"/>) aber keine folgende rechte Spalte!
			</report>
			<report
				test="not(self::tei:fw or self::tei:titlePart) and contains(@rendition, '#c')
					and not(preceding-sibling::*[contains(@rendition, '#l')])">
				mittlere Spalte (<value-of select="@rendition"/>) aber keine vorhergehende linke Spalte!
			</report>
		</rule>
	</pattern>
	
	<pattern id="quote">
		<rule context="tei:quote">
			<report sqf:fix="quote-lb" test="node()[1][self::tei:lb]">
				Quote darf nicht mit lb beginnen.
			</report>
			<sqf:fix id="quote-lb">
				<sqf:description>
					<sqf:title>erstes lb vor das quote verschieben.</sqf:title>
				</sqf:description>
				<sqf:add select="tei:lb[1]" match="." position="before"/>
				<sqf:delete match="tei:lb[1]"/>
			</sqf:fix>
		</rule>
	</pattern>
	
	<pattern>
		<rule context="tei:pc">
			<report test=". = ('//', '„', '“', '”', '&quot;') and not(ancestor::tei:quote)">
				Zitate in quote einschließen!
			</report>
			<report test="matches(., '[a-zA-Z]')">
				Text in pc!
			</report>
		</rule>
	</pattern>
	
	<pattern>
		<rule context="tei:text//text()">
			<report test="(contains(., '//') or contains(., '„') or contains(., '“') or contains(., '&quot;'))
				and not(parent::tei:pc)">
				Anführungszeichen in pc einschließen
			</report>
		</rule>
	</pattern>
	
	<pattern id="sic">
		<rule context="tei:sic">
			<report test="not(parent::tei:choice)">sic nur in choice verwenden.</report>
		</rule>
	</pattern>

	<pattern id="content">
		<rule context="tei:p | tei:table | tei:list | tei:head | tei:milestone | tei:figure">
			<report test="parent::tei:div[@type = 'page']">Content muß in div ohne @type stehen!</report>
		</rule>
	</pattern>

	<pattern id="cb">
		<rule context="tei:cb">
			<!--<report test="not(parent::tei:div[@type = 'page'])">
				cb muß direkt in der Seiten-div stehen!
			</report>-->
			<report test="not(parent::tei:div)">
				cb muß direkt innerhalb einer div stehen
			</report>
			<report test="substring(preceding-sibling::*[1]/@rendition, 1, 2)
				= substring(following-sibling::*[1]/@rendition, 1, 2)">
				vorher und nachher gleiche Ausrichtung!
			</report>
		</rule>
	</pattern>
	
	<pattern id="w">
		<rule context="tei:w">
			<report test="matches(., '\s+')">
				Keine Whitespaces innerhalb von w!
			</report>
		</rule>
	</pattern>
</schema>
