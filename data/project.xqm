xquery version "3.1";

module namespace wdbPF  = "https://github.com/dariok/wdbplus/projectFiles";

import module namespace wdb  = "https://github.com/dariok/wdbplus/wdb" at "/db/apps/edoc/modules/app.xqm";
declare namespace tei  = "http://www.tei-c.org/ns/1.0";
declare namespace meta  = "https://github.com/dariok/wdbplus/wdbmeta";

declare function wdbPF:getProjectFiles ( $model as map(*) ) as node()* {
  (
    wdbPF:getFunctionHeaders($model),
    <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/data/scripts/project.css" />,
    <script src="{$wdb:edocBaseURL}/data/scripts/project.js" />,
    <script src="{$wdb:edocBaseURL}/resources/scripts/annotate.js" />,
    <script src="https://diarium-reporting.acdh-dev.oeaw.ac.at/openseadragon/openseadragon.min.js"/>
  )
};

declare function wdbPF:getFunctionHeaders ($model as map(*)) as node()* {(
    <link rel="icon" href="https://digitarium.acdh.oeaw.ac.at/wp-content/uploads/2018/08/cropped-Digitarium-Logo-Vector-final-32x32.png" sizes="32x32" />,
    <link rel="icon" href="https://digitarium.acdh.oeaw.ac.at/wp-content/uploads/2018/08/cropped-Digitarium-Logo-Vector-final-192x192.png" sizes="192x192" />
)};

declare function wdbPF:getHeader ( $model as map(*) ) as node()* {
  let $file := doc($model("fileLoc"))
  
  let $style := if (count($file//tei:teiHeader/tei:revisionDesc//tei:item) > 2)
        then '#327e82'
        else if (count($file//tei:teiHeader/tei:revisionDesc//tei:item) = 2)
        then '#59c9d4'
        else if (count($file//tei:teiHeader/tei:revisionDesc//tei:item) = 1)
        then '#d2f6f9'
        else '#fbfbff'
    
    let $ti := if (count($file//tei:teiHeader/tei:revisionDesc//tei:item) > 2)
        then 'mehr als 2 Korrekturdurchgänge'
        else if (count($file//tei:teiHeader/tei:revisionDesc//tei:item) = 2)
        then '2 Korrekturdurchgänge'
        else if (count($file//tei:teiHeader/tei:revisionDesc//tei:item) = 1)
        then 'Ein Korrekturdurchlauf'
        else 'Keine Korrektur'
  
  return (
    <a href="start.html?id=jg17xx"><img src="https://digitarium.acdh.oeaw.ac.at/wp-content/uploads/2018/08/Digitarium-Logo-Vector-final.png" alt="Digitarium Logo" title="Digitarium – Startseite" /></a>,
    <h1>{$file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = 'main']/text()}</h1>,
    <h2 style="background-color: {$style};" title="{$ti}">{$file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = 'num']/text()}</h2>,
      <span class="dispOpts">
          <a target="_blank" href="{wdb:getUrl($model?projectResources||'hilfe.html')}">Hilfe</a> 
      </span>,
    if (sm:id()//sm:real/sm:username != 'guest') then (
      <span class="dispOpts">
        <a href="javascript:anno()">annotieren</a>
      </span>,
      <span class="dispOpts">
        <a href="javascript:highlightShort()" id="optProb">kurze Wörter anzeigen</a>
      </span>
    ) else ()
  )
};

declare function wdbPF:getImages ($id as xs:string, $page as xs:string) as xs:string {
  let $imageServer := "https://diarium-images.acdh-dev.oeaw.ac.at"
  let $file := collection('/db/apps/edoc/data/')/id($id)[self::tei:TEI]
  let $path := substring-before(substring-after(base-uri($file), 'data'),'.xml')
  let $fi := translate(substring-after($file/@xml:id, 'd_'), '-', '')
  return $imageServer || translate($path, '-', '') || '/' || $fi || '-' || format-number(xs:integer($page) - 1, '000') || '/full/full/0/default.jpg'
};

declare function wdbPF:getStart ($model as map(*)) {
  let $metas := collection($model("pathToEd"))//meta:projectMD
  let $matchPattern := ".*(\d{3})(\d)(\d{2})(\d{2})-(\d+)\..*"
  let $replacementPattern := "https://diarium-images.acdh-dev.oeaw.ac.at/$1x/$1$2/$3/$1$2$3$4/$1$2$3$4-$5"
  
  return (
    <div class="decades">
      <p id="stats"></p><span class="filter-heading">Alle Jahrgänge auswählen:</span>
      <ul>
        <li><img src="/data/resources/6848564_calendar_date_event_reminder_icon.svg" style="height:1em;" alt="Statistics for 1703–1799" /><a href="start.html?id=jg17xx">1703–1799</a></li>
      </ul>
      <span class="filter-heading">Dekaden des 18. Jahrhunderts auswählen:</span>
      <ul>{
        for $p in doc("/db/apps/edoc/data/wdbmeta.xml")//meta:ptr
        let $f := doc("/db/apps/edoc/data/" || $p/@path)
        let $d1 := substring($f//meta:date[1], 1, 4)
        let $d2 := substring($f//meta:date[2], 1, 4)
        
        return
        <li>
          <img src="/data/resources/6848564_calendar_date_event_reminder_icon.svg" style="height:1em;" alt="Statistics for {$d1}–{$d2}"/>
          <a href="start.html?id={$p/@xml:id}">{$d1}–{$d2}</a>
        </li>
      }</ul>
    </div>,
    for $meta in $metas[descendant::meta:view]
    order by $meta/@xml:id
    return
      <div class="month">
        <h1 class="content-block-title"><span class="separator-title">{substring-after($meta//meta:title/text(), '– ')}</span></h1>
        {for $st in $meta//meta:struct[meta:view]
          let $om := number($st/@order)
          order by $om
          return
            for $v in $st/meta:view
              let $file := collection("/db/apps/edoc/data")/id($v/@file)[self::tei:TEI]
              let $num := count($file//tei:teiHeader/tei:revisionDesc//tei:item)
              where $file//tei:fw
                let $style := if ($num > 2)
                    then 'nc3'
                    else if ($num = 2)
                    then 'nc2'
                    else if ($num = 1)
                    then 'nc1'
                    else 'nc0'
                let $url := replace(($file//tei:graphic)[1]/@url, $matchPattern, $replacementPattern)
                order by number($v/@order)
                let $title := normalize-space($file//tei:title[@type='num'])
                return
            <p class="issue {$style}">
                <a href="view.html?id={$v/@file}" title="Ausgabe {$title}, {$num} Korrekturdurchgänge">
                    <img src="{$url}/full/200,/0/default.jpg"
                      alt="Titelseite der Ausgabe {$title}"
                      title="Ausgabe {$title}, {$num} Korrekturdurchgänge"/>
                </a>
                <a href="view.html?id={$v/@file}" title="Ausgabe {$title}, {$num} Korrekturdurchgänge">{$title}</a>
            </p>
        }
      </div>
  )
};

declare function wdbPF:cite ($node as node(), $model as map(*)) {
  let $date := collection($wdb:data)/id($model?id)[self::meta:file]/@date
  return
  (
  <p>
    <b>Zitationshinweis allgemein:</b> Wienerisches DIGITARIUM, herausgegeben
    von Claudia Resch und Dario Kampkaspar.
    <a href="https://digitarium.acdh.oeaw.ac.at">https://digitarium.acdh.oeaw.ac.at</a> 
    (abgerufen am <time datetime="{current-dateTime()}">{
      format-date(current-date(), "[D].[M].[Y]")
    }</time>).</p>,
  <p>
    <b>Zitationshinweis für diese Ausgabe:</b> Digitaler Volltext der Ausgabe
    <i>{normalize-space(doc($model?fileLoc)//tei:title[@type = 'num'])}</i>
    (zuletzt geändert am <time datetime="{$date}">{format-date(xs:dateTime($date), "[D].[M].[Y]")}</time>),
    automatisch erstellt in Transkribus, manuell nachbearbeitet und korrigiert. In: Wienerisches DIGITARIUM,
    herausgegeben von Claudia Resch und Dario Kampkaspar.
    <a href="https://digitarium-app.acdh.oeaw.ac.at">https://digitarium-app.acdh.oeaw.ac.at/view.html?id={$model?id}</a>
    (abgerufen am <time datetime="{current-dateTime()}">{format-date(current-date(), "[D].[M].[Y]")}</time>).</p>,
  <p>
    <b>Persistent Identifier:</b>
    <br />Diese Ausgabe: <a href="{doc($model?infoFileLoc)/id($model?id)/@pid}">{string(doc($model?infoFileLoc)/id($model?id)/@pid)}</a>
    <br />Diese Jahrgang: <a href="{doc($model?infoFileLoc)//meta:projectID/@pid}">{string(doc($model?infoFileLoc)//meta:projectID/@pid)}</a>
  </p>
)};

declare function wdbPF:getNumIss ($node as node(), $model as map(*)) {
    <span>{count(collection("/db/apps/edoc/data")//tei:TEI[descendant::tei:revisionDesc[descendant::tei:item]])}</span>
};

declare function wdbPF:getRestView ($fileID) {
  let $doc := collection($wdb:data)/id($fileID)
  return 
    <view xmlns="https://github.com/dariok/wdbplus/wdbmeta">{(
      attribute file { $fileID },
      attribute label { $doc//tei:title[@type = 'num'] },
      attribute order { substring-after(substring-before($doc//tei:title[@type = 'num'], ','), ' ') }
    )}</view>
};

declare function wdbPF:noske($id as xs:string, $process as element()) {
  let $file := collection("/db/apps/edoc/data")/id($id)[self::tei:TEI]
  
  let $div := for $div in $file//tei:text/*/*
    let $p := for $p in $div/tei:*[descendant::tei:w]
      let $w := for $w in ($p//tei:w | $p//tei:pc) return
        normalize-space($w) || "	" || $w/@xml:id
      return
        '
<p id="' || $p/@xml:id || '">
' || string-join($w, "
") || '
</p>'
    return
      '
<div id="' || $div/tei:pb/@xml:id || '">'
      || string-join($p, "") || '
</div>'
  
  return
    '<doc id="' || $id || '" date="' || current-dateTime() || '">'
    || string-join($div, "") || '
</doc>
'
};
