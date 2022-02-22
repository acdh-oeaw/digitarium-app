$(function (e) {
  $('.month').has('p').css('display', 'flex');
});
$(document).ready(function () {
  $('option[value=' + params.id + ']').attr("selected", "selected");
});

$(document).ready(function () {
  let y = params['id'].substr(2, 3);
  let text = (y == "17x") ? "1703–1799" : y + "0–" + y + "9";
  getStats(y, text);
  
  $('.decades img').on('mouseover', function () {
    let tempText = $(this).prev('a').text();
    let tempY = $(this).prev('a').attr('href').substr(16, 3);
    getStats(tempY, tempText);
  }).on('mouseout', function () {
    getStats(y, text);
  });
});

function getStats (y, text) {
  let s = (y == "17x") ? "" : "?y=" + y + "x";
  $.ajax({
    url: "/data/resources/stats.xql" + s,
    success: function (data) {
      $('#stats').empty();
      $('<span>Insgesamt ' + $(data)
        .find('p')
        .attr('num') + ' Ausgaben ' + text + ':</span>')
        .appendTo('#stats');
      $('<br>').appendTo('#stats');
      $('<div>').appendTo('#stats');
      $(data).find('div.single-bar').each(function () {
        $("<div />")
          .html($(this).html())
          .css('flex-basis', $(this).attr('width') + '%')
          .addClass($(this).attr('class'))
          .appendTo('#stats > div');
      });
    }
  });
}