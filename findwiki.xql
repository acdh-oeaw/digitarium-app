xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace kwic      = "http://exist-db.org/xquery/kwic";

let $base := '/db/apps/edoc/data/'

let $labels := doc($base || 'wgwiki.xml')//tei:list/tei:item

return <html><head></head><body>{
    for $l in $labels
    let $q := <query><phrase>{normalize-space(translate(replace(translate($l/tei:label, '"/()', '“'), '\d*', ''), ',', ' '))}</phrase></query>
    let $hit := ft:query(collection($base || '1700/1703')//tei:p, $q)
    return if (count($hit) = 0) then () else ( 
        <head>{$q}</head>,
        <table>{
            for $h in $hit return <tr><td>{$h/@xml:id}</td><td>{kwic:summarize($h, ())}</td></tr>
        }</table>
    )
}</body></html>
