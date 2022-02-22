function loadTargetImage () {
  var target = $(':target');
  if (target.length > 0) {
    if (target.attr('class') == 'pagebreak') {
      console.log($(':target .pb a').attr('href'));
      displayImage($(':target .pb a'));
    } else {
      let pagebreak = target.parents().has('.pagebreak').first();
      let pb = (pagebreak.find('a').length > 1)
        ? pagebreak.find('.pb a')
        : pb = pagebreak.find('a');
      displayImage(pb);
    }
  } else {
    console.log('no target - logout?');
  }
}

function displayImage(element) {
  if (window.innerWidth > 768) {
    let ln = element.attr('href').toString(),
        fa = ln.substr(ln.indexOf('facs_')),
        pos = fa.substr(5, fa.indexOf('.') - 5) - 1;
    viewer.goToPage(pos);
  }
}

function highlightShort() {
    id = $("meta[name='id']").attr("content");
    $('#optProb').text('hi+w anzeigen');
    $('#optProb').attr('href', 'javascript:highlightHi()');
    
    get = $.getJSON(
        "data/scripts/xquery/short.xql",
        {file: id, type: 'w'},
        function(data) { highlight(data); }
    );
};

function highlightHi() {
    id = $("meta[name='id']").attr("content");
    $('#optProb').text('Wortgrenzen einblenden');
    $('#optProb').attr('href', 'javascript:showWordBoundaries()');
    
    $(".w").css('background-color', '');
    $(".w").attr('title', '');
    
    get = $.ajax({
    	dataType: "json",
    	url: "data/scripts/xquery/short.xql",
    	data: {file: id, type: 'hi'},
    	success: function(data) { highlight(data); }
    });
};

function showWordBoundaries() {
	$('#optProb').text('Probleme ausblenden');
	$('#optProb').attr('href', 'javascript:clearProbs()');
	
	$("span:nth-child(odd)").css('background-color', 'skyblue');
	$("span:nth-child(even)").css('background-color', 'chocolate');
	$(".w").attr('title', '');
};

function clearProbs() {
	$('#optProb').text('kurze Wörter anzeigen');
    $('#optProb').attr('href', 'javascript:highlightShort()');
    $(".w").css('background-color', 'transparent');
    $(".w").attr('title', '');
};

function highlight(data) {
	$.each(
        data,
        function( index, value ) {
            id = '#' + value.id;
            $(id).css('background-color', 'skyblue');
            $(id).attr('title', id + ': ' + value.text);
        }
    );
};

/* when hovering over a footnote, display it in the right div */
$(document).ready(function () {
    $('.fn_number').hover(mouseIn, mouseOut);
});

function fraktur() {
	$('#wdbContent').css("font-family", "UnifrakturMaguntia");
	$(".italic").css("font-style", "inital");
	$(".italic").css("font-family", "mufi");
	$("#optFrakt").attr("href", "javascript:antiqua()");
	$("#optFrakt").text('Fraktur aus');
};
function antiqua() {
	$('#wdbContent').css("font-family", "mufi");
	$(".italic").css("font-style", "italic");
	$("#optFrakt").attr("href", "javascript:fraktur()");
	$("#optFrakt").text('Fraktur ein');
};

var overlay = false;
$(document).ready(function(){
  $('.w').on('click', function(e){
    var idx = $(this).index();
    var data = [];
    let anc = $(this).parents('p, head, label, item, td').find('.invisible');
    anc.each(function(index){
    	if ($(this).parent('.w').length > 0) {
    		if ($(this).parent().index() <= idx) data.push($(this));
    	} else {
    		if ($(this).index() <= idx) data.push($(this));
    	}
    });
    let rect = data.pop()[0].dataset.rect;
    
    let re = rect.split(' ');
    let ol = re[0];
    let ur = re[2];
    
    let ulx = parseInt(ol.substr(0, ol.indexOf(',')));
    let uly = parseInt(ol.substr(ol.indexOf(',')+1));
    let lrx = parseInt(ur.substr(0, ur.indexOf(',')));
    let lry = parseInt(ur.substr(ur.indexOf(',')+1));
    let wi = lrx - ulx;
    let he = lry - uly;
    let vr = viewer.viewport.imageToViewportRectangle(ulx, uly, wi, he);
    
    viewer.removeOverlay("runtime-overlay");
    if (overlay == rect) {
      overlay = false;
    } else {
      var elt = document.createElement("div");
      elt.id = "runtime-overlay";
      elt.className = "highlight";
      viewer.addOverlay({
        element: elt,
        location: vr
      });
      overlay = rect;
    }
  });
});