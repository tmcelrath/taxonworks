$(document).ready(function() {
  if($("#show").length) {
    show();
  }
});

function show() {
  $("[view-bottom]").click(function() {
    $("[data-view='development']").toggle();
  });

  $('.menu-drop').each( function() {
    if($(this).find('a').length < 1) {
      $(this).addClass("disable");
    }
  });

  $('[data-arrow]').each( function() {
    if($(this).is('span')) {
      $(this).addClass("disable");
    }
  });

  if(!$('#validation-panel li').length) {
    $('#validation-panel').hide();
  }  

  function isEmpty( el ){
      return !$.trim(el.html())
  }


  $('.panel').each( function() {
    if($(this).find('.information-panel').length) {
      if(isEmpty($(this).find('.information-panel'))) {
        $(this).find('.information-panel').parent().parent().hide();
      }
    }
  }); 

  createShortcut("left", "Go to previous", "Taxon names browse", function() {
    if($('[data-arrow="back"]').is('a')) {
      location.href = $('[data-arrow="back"]').attr('href');
    }
  });

  createShortcut("right", "Go to next", "Taxon names browse", function() {
    if($('[data-arrow="next"]').is('a')) {
      location.href = $('[data-arrow="next"]').attr('href');
    }
  });    

  createShortcut("up", "Go to ancestor", "Taxon names browse", function() {
    if($('[data-arrow="back"]').is('a')) {
      location.href = $('[data-arrow="ancestor"]').attr('href');
    }
  });

  createShortcut("down", "Go to descendant", "Taxon names browse", function() {
    if($('[data-arrow="descendant"]').is('a')) {
      location.href = $('[data-arrow="descendant"]').attr('href');
    }
  });      
}