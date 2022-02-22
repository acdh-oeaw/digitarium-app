$('document').ready($.get("./data.json", function(data) {
    // total number of issues and pages; change as needed
    var totalIssues = 423, totalPages = 7500;

    var unique = {};
    var js = data.data;
    for (i in js) {
        if (js[i].titel.substring(0, 2) != 'wd') { continue; }
        else
        if (!unique[js[i].id]) {
            unique[js[i].id] = [];
            unique[js[i].id]['N'] = 0;
            unique[js[i].id]['F'] = 0;
        }
        if (js[i].status == 'FINAL' || js[i].status == 'GT' || js[i].status == 'DONE') {
            unique[js[i].id]['F']++;
        } else {
            unique[js[i].id]['N']++;
        }
    }
    var progressIssues = Object.keys(unique).length;
    //console.log(Object.keys(unique));
    var progressPages = js.length;

    var donePages = 0, doneIssues =0;
    for (i in unique) {
        if (unique[i]['N'] == 0) {
            doneIssues++;
        }
        donePages += unique[i]['F'];
    }

    var result, relOnlineIssues=0, relOnlinePages=0;
    $.ajax({
        url: 'https://diarium-reporting-exist.minerva.arz.oeaw.ac.at/exist/apps/edoc/data/reporting.xql',
        dataType: 'json',
        success: function (data) {
        console.log(data);
        //result = JSON.parse(data);
        //console.log(result);
        relOnlineIssues = 400*data.files/totalIssues;
        relOnlinePages = 400*data.pages/totalPages;

        tpI = progressIssues - doneIssues;
        tdI = doneIssues - data.files;
        tpP = progressPages - donePages;
        tdP = donePages - data.pages;

        $('.opages').css('width', relOnlinePages+'px');
        $('.oissues').css('width', relOnlineIssues+'px');
        //$('#np').text(data.pages + textOnline + donePages + textDone + progressPages + textProgress + totalPages + textPages);
        //$('#ni').text(data.files + textOnline + doneIssues + textDone + progressIssues + textProgress + totalIssues + textIssues);
        $('#np').text(data.pages + textOnline + tdP + textDone + tpP + textProgress + totalPages + textPages);
        $('#ni').text(data.files + textOnline + tdI + textDone + tpI + textProgress + totalIssues + textIssues);
        },
        error: function (error) { console.log(error); }
    });

    var relIssues = 400*progressIssues/totalIssues;
    var relPages = 400*progressPages/totalPages;
    var relDoneIssues = 400*doneIssues/totalIssues;
    var relDonePages = 400*donePages/totalPages;

    // Read lang from URL, need to tackle CORS problems, too
    var url = (window.location != window.parent.location)
            ? document.referrer
            : document.location.href;
    if (url.indexOf('/en/') == -1) {
        var textDone = ' fertig, ', textProgress = ' in Arbeit von ', textPages = ' Seiten', textIssues = ' Ausgaben', textOnline = ' online, ';
    } else {
        var textDone = ' completed, ', textProgress = ' in progress of ', textPages = ' pages', textIssues = ' issues', textOnline = ' online, ';
        $('h1.page_title').text('Wien[n]erisches Diarium: progress report');
        $('th').eq(1).text('Document');
        $('th').eq(2).text('Page');
        $('th').eq(3).text('Date');
        $('th').eq(5).text('# of regions');
        $('th').eq(6).text('# of lines');
        $('th').eq(7).text('# of words');
    }

    $('.pages').css('width', relPages+'px');
    $('.dpages').css('width', relDonePages+'px');
    //$('.opages').css('width', relOnlinePages+'px');
    //$('#np').text(donePages + textDone + progressPages + textProgress + totalPages + textPages);
    $('.issues').css('width', relIssues+'px');
    $('.dissues').css('width', relDoneIssues+'px');
    //$('.oissues').css('width', relOnlineIssues+'px');
    //$('#ni').text(doneIssues + textDone + progressIssues + textProgress + totalIssues + textIssues);
}));