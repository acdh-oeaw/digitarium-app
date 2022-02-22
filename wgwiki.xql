xquery version "3.1";

declare variable $baseUrl := "https://www.geschichtewiki.wien.gv.at/api.php?action=ask&amp;format=xml&amp;query=";

declare function local:query($cat, $token) {
    let $query := if ($cat="Personen")
        then encode-for-uri("[[Kategorie:Personen]][[Geburtsdatum::<1800-01-01]]")
        else encode-for-uri("[[Kategorie:" || $cat || "]][[Datum_von::<1800-01-01]] OR [[Kategorie:" || $cat || "]][[Jahr_von::<1800]]")
    let $url := if (normalize-space($token) != "")
    then $baseUrl || $query || "|offset=" || $token
    else $baseUrl || $query

    let $r := doc($url)
    let $s := if ($r//subject)
    then update insert $r//subject into doc('/db/test/text/wiki/' || $cat || '.xml')/entries
    else ()

    return if ($r//@query-continue-offset)
    then local:query($cat, $r//@query-continue-offset)
    else $url
};

let $category := ("Bauwerke", "Topografische_Objekte", "Personen", "Organisationen", "Ereignisse")

return for $cat in $category
    let $s := xmldb:store('/db/test/text/wiki', $cat || '.xml', <entries/>)
    return local:query($cat, ())
