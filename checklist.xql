xquery version "3.1";

module namespace wdbq = "https://github.com/dariok/wdbplus/wdbq";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace anno = "annotate";

declare function wdbq:query($model as map(*)) {
let $coll := collection('/db/apps/edoc/data')

let $anno := doc('/db/apps/edoc/anno.xml')/anno:anno
let $n := ($coll//tei:list[parent::tei:revisionDesc and count(tei:item) < 3], $coll//tei:teiHeader[not(tei:revisionDesc)])

return(
  <aside>
    <h1>{count($n)} Ausgaben zu kontrollieren</h1>
  </aside>,
  <main>
    <table>{
        for $f in $n
            let $u := base-uri($f)
            where matches($u, '\d+-\d+-\d+')
            
            let $num := if ($f[self::tei:list])
                then count($f/tei:item)
                else 0
            let $id := "edoc_wd_" || substring($u, 33, 10)
            let $ti := normalize-space($f/ancestor-or-self::tei:teiHeader//tei:title[@type='num'])
            let $title := (if (string-length($ti) > 0) then $ti else (),
                $id,
                base-uri($f))[1]
            
            let $status := if ($anno//anno:file[. = $id])
                then true()
                else false()
            
            let $form :=
                <form>{
                    for $c in (1 to 3)
                        return if ($c <= $num)
                            then <label style="text-decoration: line-through;">{if($c > 1) then "– " else ()}{$c}. Durchgang: <input type="checkbox" name="c{$c}" checked="checked" /></label>
                            else <label>{if($c > 1) then "– " else ()}{$c}. Durchgang: <input type="checkbox" name="c{$c}" /></label>
                }{if ($status) then ", Annotationen vorhanden" else ", noch keine Annotationen vorhanden"}</form>
            
            let $style := if ($num > 2)
		        then 'green'
		        else if ($num = 2)
		        then 'yellow'
		        else if ($num = 1)
		        then 'orange'
		        else 'red'
            return <tr><td><a href="view.html?id={$id}">{$title}</a></td><td><span style="background-color: {$style}; width: 150px; display:inline-block;">{$num}</span></td><td>{$form}</td></tr>
    }</table>
  </main>)
};