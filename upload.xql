xquery version "3.1";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace debug = "https://github.com/dariok/wdbplus/debug";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";

import module namespace console = "http://exist-db.org/xquery/console";

declare function local:createColl($decade as xs:string, $year as xs:string, $month as xs:string) {
    let $dcoll := '/db/apps/edoc/data/' || $decade
    let $yColl := if (not(xmldb:collection-available('/db/apps/edoc/data/' || $decade || '/' || $year)))
        then
            let $coll := xmldb:create-collection($dcoll, $year)
            let $cm := sm:chmod($coll, 'rwxr-xr-x')
            let $pMeta := doc($dcoll || '/wdbmeta.xml')
            let $struct := <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta" file="jg{$year}" label="{$year}" order="{substring($year, 4, 1)}" />
            let $upd := update insert $struct into $pMeta/meta:projectMD/meta:struct
            
            return $coll
        else $dcoll || '/' || $year
    
    let $meta := if (doc-available($yColl||'/wdbmeta.xml'))
        then doc($yColl||'/wdbmeta.xml')
        else
            let $d1 := console:log("create yColl")
            let $m :=
<projectMD xmlns="https://github.com/dariok/wdbplus/wdbmeta" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="https://github.com/dariok/wdbplus/wdbmeta https://raw.githubusercontent.com/dariok/wdbmeta/master/wdbmeta.xsd"
  xml:id="jg{$year}">
  <projectID>jg{$year}</projectID>
  <titleData>
    <title>Wiennerisches Diarium – {$year}</title>
    <date>{$year}-01-01</date>
    <date>{$year}-12-31</date>
    <place ref="https://d-nb.info/gnd/4066009-6">Wien</place>
    <language>de-Goth-AT</language>
    <language>la</language>
    <language>fr</language>
    <language>it</language>
    <type>Newspaper</type>
  </titleData>
  <metaData>
    <contentGroup>
      <content xml:id="originalImages">
        <description>Original images</description>
      </content>
      <content xml:id="processedImages">
        <description>Deskewed and otherwise processed images</description>
      </content>
      <content xml:id="fulltext">
        <description>Proofread full text</description>
      </content>
    </contentGroup>
    <involvement>
      <org role="publisher disseminator editor" xml:id="oeaw" contribution="fulltext processedImages">Österreichische Akademie der Wissenschaften</org>
      <org role="imageProvider" xml:id="oenb" contribution="originalImages">Österreichische Nationalbibliothek</org>
    </involvement>
    <legal>
      <licence content="originalImages" href="http://anno.onb.ac.at/faq.htm">Original Images taken from the ANNO proced</licence>
      <licence content="processedImages">Images deskewed and otherwise post-processed</licence>
      <licence content="fulltext" href="https://creativecommons.org/licenses/by-sa/4.0/legalcode.de">High quality full text</licence>
    </legal>
  </metaData>
  <files />
  <process target="html">
    <command type="xsl">/db/apps/edoc/data/xslt/tei-transcript.xsl</command>
  </process>
  <struct label="{$year}" order="{$year}">
    <import path="../wdbmeta.xml"/>
  </struct>
</projectMD>
            let $s := xmldb:store($yColl, 'wdbmeta.xml', $m)
            let $cm := sm:chmod($s, 'rw-r--r--')
            let $d2 := console:log($m)
            let $d2a := console:log($s)
            return doc($s)
            
    let $mColl := if(xmldb:collection-available($yColl || '/' || $month))
        then $yColl || '/' || $month
        else 
            let $mc := xmldb:create-collection($yColl, $month)
            let $cm := sm:chmod($mc, 'rwxr-xr-x')
            return $mc
    
    return $mColl
};
  
let $user := sm:id()//sm:real/sm:username
return if (not(sm:get-group-members('diarium') = $user))
  then <p>Keine Schreibberechtigung für Benutzer / No permission to write for user {$user}
    <span>{sm:get-group-members('diarium')}</span>
        {
            let $debugFile := doc('/db/apps/edoc/data/debug.xml')
            let $error := <debug:error where="convert2.xql" action="check login">User: {$user}</debug:error>
            let $t := update insert $error into $debugFile
            return $t
        }
    </p>
  else
    let $origFileData := request:get-data()
    return if (string-length($origFileData) > 0)
    then
      let $d3 := console:log(string-length($origFileData))
      let $origfilename := $origFileData//tei:title[@type='main']
        
      let $decade := substring($origfilename, 3, 3) || 'x'
      let $year := substring($origfilename, 3, 4)
      let $month := substring($origfilename, 7, 2)
      let $day := substring($origfilename, 9, 2)
        
    (:let $file := util:base64-decode($origFileData):)
    let $file := $origFileData
    
    let $colls := local:createColl($decade, $year, $month)
        
    let $filename := $year || '-' || $month || '-' || $day || '.xml'
    
    (: ambiguous rule match soll nicht zum Abbruch führen :)
    let $attr := <attributes><attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" /></attributes>
    
    let $p0 := $file
    let $t0 := transform:transform($p0, doc('/db/apps/edoc/data/refactor/transkribus2tei.xsl'), (), $attr, "expand-xincludes=no")
    let $t := console:log('p0')
    let $t1 := transform:transform($t0, doc('/db/apps/edoc/data/refactor/tok.xsl'), (), $attr, "expand-xincludes=no")
    let $t := console:log('p1')
    let $t2 := transform:transform($t1, doc('/db/apps/edoc/data/refactor/tok1.xsl'), (), $attr, "expand-xincludes=no")
    let $t := console:log('p2')
    let $t3 := transform:transform($t2, doc('/db/apps/edoc/data/refactor/tok2.xsl'), (), $attr, "expand-xincludes=no")
    let $t := console:log('p3')
    let $t4 := transform:transform($t3, doc('/db/apps/edoc/data/refactor/tok3.xsl'), (), $attr, "expand-xincludes=no")
    let $t := console:log('p4')
    let $t5 := transform:transform($t4, doc('/db/apps/edoc/data/refactor/tok4.xsl'), (), $attr, "expand-xincludes=no")
    let $t := console:log('p5')
    let $t6 := transform:transform($t5, doc('/db/apps/edoc/data/refactor/tok5.xsl'), (), $attr, "expand-xincludes=no")
    let $t := console:log('p6')
    let $xml := transform:transform($t6, doc('/db/apps/edoc/data/refactor/tok6.xsl'), (), $attr, "expand-xincludes=no")
    
    let $store := xmldb:store($colls, $filename, document{$xml})
    let $co := sm:chown($store, 'user')
    let $cg := sm:chgrp($store, 'diarium')
    let $cm := sm:chmod($store, 'rw-r--r--')
    let $location := substring-after(substring-after($store, $decade), $year||'/')
    let $d4b := console:log($store)
    let $d4c := console:log($year)
    let $d4d := console:log($location)
    
    let $stored := doc($store)
    let $ti := $stored//tei:title[@type = 'num']
    let $titel := if ($ti = '') then '??' else $ti
    let $id := $stored//tei:TEI/@xml:id
    
    let $wdbmeta := doc('/db/apps/edoc/data/' || $decade || '/' || $year || '/wdbmeta.xml')
    (: PID eintragen, falls beretits vorhanden :)
    let $addPID := if($wdbmeta/id($id)/@pid)
      then update 
        insert <idno xmlns="http://www.tei-c.org/ns/1.0" type="URI">{string($wdbmeta/id($id)/@pid)}</idno>
        into $stored//tei:publicationStmt
      else ()
    (: Bearbeitungsstand eintragen :)
    let $addEdit := if(count($stored//tei:revisionDesc//tei:item) = 0)
      then update insert (<item xmlns="http://www.tei-c.org/ns/1.0">Korrektur {current-dateTime()}</item>,
          <item xmlns="http://www.tei-c.org/ns/1.0">Korrektur {current-dateTime()}</item>) into $stored//tei:revisionDesc/tei:list
      else update insert (<item xmlns="http://www.tei-c.org/ns/1.0">Korrektur {current-dateTime()}</item>) into $stored//tei:revisionDesc/tei:list
    
    (: Eintrag in wdbmeta erstellen oder updaten :)
    let $fileEntry := $wdbmeta//meta:file[@xml:id = $id]
    let $i2 := if ($fileEntry)
        then
            let $u1 := update value $fileEntry/@uuid with util:uuid($stored)
            let $u2 := update value $fileEntry/@date with xmldb:last-modified('/db/apps/edoc/data/' || $decade 
                || '/' || $year || '/' || $month, $filename)
              return ()
        else
            let $file := <file xmlns="https://github.com/dariok/wdbplus/wdbmeta"
                path="{$location}" xml:id="{$id}" uuid="{util:uuid($stored)}"
                date="{xmldb:last-modified('/db/apps/edoc/data/' || $decade || '/' || $year || '/' || $month,
                    $filename)}" />
            let $i1 := update insert $file into $wdbmeta//meta:files
            let $d4 := console:log($file)
            return ()
    
  (: Struct für Monat erstellen :)
    let $mStruct := if ($wdbmeta//meta:struct[@order = $month])
        then $wdbmeta//meta:struct[@order = $month]
        else
            let $months := ('Jänner', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember')
            let $str := <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta"
                label="{$months[xs:int($month)]}" order="{$month}" />
            let $i2 := update insert $str into $wdbmeta//meta:struct[@label = $year]
            let $d5a := console:log($str)
            return $wdbmeta//meta:struct[@order = $month]
      
      (: Struct für die Ausagbe erstellen oder updaten :)
        let $order := analyze-string($titel, '\d+')/fn:match[1]
        
        let $viewEntry := $wdbmeta//meta:view[@file = $id]
        let $i2 := if ($viewEntry)
            then 
                let $u3 := if ($titel != "") then update value $viewEntry/@label with $titel else ()
                let $u4 := if ($order != "") then update value $viewEntry/@order with $order else ()
                let $u5 := if ($viewEntry/@private = "true") then update value $viewEntry/@private with "false" else ()
                return ()
            else
                let $struct := <view xmlns="https://github.com/dariok/wdbplus/wdbmeta"
                    file="{$id}" label="{$titel}" order="{$order}" />
                  let $i3 := update insert $struct into $mStruct
                  let $d4a := console:log($struct)
                  return ()
              
    return "https://diarium-reporting-exist.minerva.arz.oeaw.ac.at/exist/apps/edoc/view.html?id=" || $id
  else <p>Keine Daten</p>