xquery version "3.1";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace tei="http://www.tei-c.org/ns/1.0";

let $user := sm:id()

let $base := "/db/apps/edoc/data"
let $coll := collection($base)
let $months := ('Jänner', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember')

return for $meta in $coll//meta:projectMD
    let $files := for $f in $meta//meta:file
        let $id := $f/@xml:id
        let $title := $coll/id($id)//tei:title[@type='num']
        let $order := format-number(substring-after(substring-before($title, ','), 'Nr. '), '000')
        let $label := $title
        return <meta:view file="{$id}" label="{$label}" private="true" order="{$order} "/>
    let $v := for $f in $files
        let $m := analyze-string($f/@label, '[JFMASOND]\w+')/fn:match
        let $o := index-of($months, $m)
        group by $o
        return <meta:struct label="{$m[1]}" order="{format-number($o, '00')}">{$f}</meta:struct>
    let $y := substring(base-uri($meta), 25, 4)
    let $s := <meta:struct label="{$y}" order="{$y}">{$v}</meta:struct>
    return (update insert $s into $meta/meta:struct,
        update value $meta/meta:projectID with "wd"||$y,
        update value $meta//meta:title with "Wien[n]erisches Diarium – "||$y)