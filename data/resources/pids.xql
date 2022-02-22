xquery version "3.1";

import module namespace httpclient="http://exist-db.org/xquery/httpclient";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $year := request:get-parameter("y", "")
let $coll := substring($year, 1, 3) || "x/" || $year
let $meta := doc("/db/apps/edoc/data/" || $coll || '/wdbmeta.xml')

let $req := "http://pid.gwdg.de/handles/21.11115/"
let $headers :=
  <headers>
    <header name="Authorization" value="Basic dXNlcjIxLjExMTE1LTAxOlg5MXl1Vmx3aTQ=" />
    <header name="Accept" value="application/json" />
    <header name="Content-Type" value="application/json" />
  </headers>

let $pids := for $file in $meta//*:file
  let $tei := collection("/db/apps/edoc/data/" || $coll)/id($file/@xml:id)[self::tei:TEI]
  return
    if (not($file/@pid))
    then
      let $url := "https://digitarium-app.acdh.oeaw.ac.at/view.html?id=" || $file/@xml:id
      let $content := '[{"type": "URL", "parsed_data": "' || $url || '"}]'
      
      let $response := httpclient:post(
        xs:anyURI($req),
        $content,
        true(),
        $headers
      )
      
      let $map := parse-json(util:base64-decode($response//*:body[1]))
      let $pid := "http://hdl.handle.net/" || $map?epic-pid
      let $att := attribute pid { $pid }
      let $ins := update insert $att into $file
      let $insf := update 
        insert <idno xmlns="http://www.tei-c.org/ns/1.0" type="URI">{ string($pid) }</idno>
        into $tei//tei:publicationStmt
      return $file/@xml:id || ":" || $pid
    else if (not($tei//tei:publicationStmt/tei:idno))
    then 
      let $pid := $file/@pid
      let $insf := update 
        insert <idno xmlns="http://www.tei-c.org/ns/1.0" type="URI">{ string($pid) }</idno>
        into $tei//tei:publicationStmt
        return "inserted " || $pid || " as idno into " || base-uri($tei)
    else ()
let $pidm := if (not($meta//*:projectID/@pid))
  then
    let $content := '[{"type": "URL","parsed_data": "https://digitarium-app.acdh-dev.oeaw.ac.at/data/' || $coll || '/wdbmeta.xml"}]'
    let $response := httpclient:post(
      xs:anyURI($req),
      $content,
      true(),
      $headers
    )
    let $map := parse-json(util:base64-decode($response//*:body[1]))
    let $pid := "http://hdl.handle.net/" || $map?epic-pid
    let $att := attribute pid { $pid }
    let $ins := update insert $att into $meta//*:projectID
    return base-uri($meta) || ':' || $pid
  else ()

return <result> <s>{$pids}</s> <m>{$pidm}</m></result>
  
(:  let $request := <http:request:)
(:        href="{$req}":)
(:        method="post":)
(:        username="{$user}":)
(:        password="{$pass}":)
(:        auth-method="basic":)
(:        send-authorization="true">:)
(:      <http:header name="Accept" value="application/json" />:)
(:      <http:body media-type="application/json">:)
(:        {$content}:)
(:      </http:body>:)
(:    </http:request>:)
(:let $response := http:send-request($request):)