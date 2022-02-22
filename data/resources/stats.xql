xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

let $coll := "/db/apps/edoc/data/"
let $dec := request:get-parameter('y', '')

let $numbers := for $f in collection($coll || $dec)/tei:TEI
  group by $num := count($f//tei:item[ancestor::tei:revisionDesc])
  order by $num
  where $num > 0
  return <e num="{$num}" count="{count($f)}" />

let $total := sum($numbers/@count)
return
  <p num="{$total}">
    <div id="bar-chart">
    {
    for $i in $numbers
      let $rel := 100 * $i/@count div $total
      order by $i/@num descending
      return <div class="nc{$i/@num} single-bar" width="{$rel}"><span><img src="/data/resources/5288411_document_location_map_news_newspaper_icon.svg" style="height:1em;" alt="Anzahl der Ausgaben"/> {string($i/@count)}</span></div>
    }
    </div>
  </p>
