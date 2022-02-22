xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

let $id := request:get-parameter('file', '')
let $type := request:get-parameter('type', 'w')

let $doc := if ($id = '') 
    then doc('/db/apps/edoc/data/1700/1703/08/1703-08-13.xml')
    else collection('/db/apps/edoc/data')/id($id)

let $result := if ($type = 'w')
    then
        let $ws := $doc//tei:w[not(parent::tei:fw)
            and string-length() < 4]
        
        return for $w in $ws
            where not(normalize-space($w) = ( 
                'als', 'Auß', 'auß', 
                'bey', 'biß', 
                'das', 'Daß', 'daß', 'dem', 'Dem', 'DEn', 'Den', 'den', 'der', 'Der', 'deß', 'die', 'Die',
                'ein',
                'Fuß',
                'hat', 'Hat', 'her', 'hin', 
                'in', 'In', 'ist',
                'Jhr',
                'Man', 'man', 'mit', 'Mit', 
                'Num',
                'ob',
                'sey', 'sie', 'so', 
                'Tag', 
                'Uhr', 'umb', 'und', 
                'vom', 'von', 
                'was', 'wer', 'wie', 'Wie', 'wir',
                'zu'))
                and (not (matches($w, '\d+') or $w/following-sibling::node()[1][self::tei:pc]))
            (:return <w xml:id="{$w/@xml:id}">{normalize-space($w)}</w>:)
            return map { "id": xs:string($w/@xml:id), "text": normalize-space($w) }
    else
        for $w in $doc//tei:hi[following-sibling::node()[1][self::tei:w]]/tei:w[not(following-sibling::tei:w)]
        	(:return <w xml:id="{$w/@xml:id}">{normalize-space($w)}</w>:)
        	return map { "id": xs:string($w/@xml:id), "text": normalize-space($w) }

return if (count($result) = 1)
	then [ $result ]
	else $result