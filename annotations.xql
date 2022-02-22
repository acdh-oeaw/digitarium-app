xquery version "3.1";

declare namespace anno = "annotate";

let $file := 'edoc_wd_1722-10-31'

let $doc := doc('/db/apps/edoc/anno.xml')

let $old := 
    for $e in $doc//anno:entry[anno:file=$file]
        return $e//@from ||'–'||$e//@to||': '||$e//*:cat
let $before := count($doc//anno:entry)
let $del := update delete $doc//anno:entry[anno:file=$file]

return ($before, $old, count($doc//anno:entry))