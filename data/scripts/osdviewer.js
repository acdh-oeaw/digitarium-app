if (window.innerWidth > 768) {
  $.holdReady(true);
  console.log('holding');
  
  let tiles = [];
  getTiles ( tiles );
    
  if (tiles.length == 0) {
    console.info("no images found on page");
    console.log("ready");
    $.holdReady(false);
  } else {
    var viewer = OpenSeadragon({
      preserveViewport: true,
      visibilityRatio: 1,
      defaultZoomLevel: 0,
      id: "fac",
      sequenceMode: true,
      tileSources: [],
      showFullPageControl: false,
      showHomeControl: false,
      prefixUrl: "https://cdn.jsdelivr.net/npm/openseadragon@2.4/build/openseadragon/images/"
    });
    
    var osdPageHandler = function(source, page, data){
      $('#pag' + (source.page + 1))[0].scrollIntoView();
    };
    viewer.addHandler('page', osdPageHandler);
    
    viewer.addOnceHandler('open', function(event) {
      $.holdReady(false);
      console.log('ready');
    });
    viewer.addHandler('open-failed', function ( eventData ) {
      console.error("opening image failed");
      console.error(eventData);
      console.log("ready");
      $.holdReady(false);
    });
    viewer.addHandler('tile-load-failed', function ( eventData ) {
      console.error("loading image failed");
      console.error(eventData);
      console.log("ready");
      $.holdReady(false);
    });
    
    viewer.open(tiles);
  }
}

function getTiles ( tiles ) {
  $('.pagebreak a').each(function(){
        let img = {
            type: 'image',
            url: $(this).attr('href')
        };
        tiles.push(img);
    });
}
