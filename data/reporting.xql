xquery version "3.1";

declare namespace output	= "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei		= "http://www.tei-c.org/ns/1.0";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace http   = "http://expath.org/ns/http-client";

declare option output:method "json";

import module namespace wdb	= "https://github.com/dariok/wdbplus/wdb"	at "../modules/app.xqm";

let $header := response:set-header('Access-Control-Allow-Origin', 'https://diarium-reporting.acdh-dev.oeaw.ac.at')

let $coll := collection($wdb:edocBaseDB || '/data')

let $public := $coll//meta:view[not(@private=true())]/@file
let $fil := $coll//tei:TEI[@xml:id = $public]

let $files := count($fil)
let $pages := count($fil//tei:pb)

return <root><pages>{$pages}</pages><files>{$files}</files></root>