$(document).ready(function() {
  var saving = false;

  function save(callback) {
    if (saving) return;

    saving = true;

    var pos = $('.heading').position();
    $('.ajax_load').css('position', 'absolute');
    $('.ajax_load').css('left', pos.left+$('.heading').width()+10);
    $('.ajax_load').css('top', pos.top+($('.heading').height()/2)-($('.ajax_load').height()/2));
    $('.ajax_load').show();

    var items = [];
    $('.todo_item').each(function() {
      var item = {};
      item['complete'] = $('.complete', this).attr('checked');
      item['description'] = $('.description', this).text();
      items.push(item);
    });

    $.post('/todo/ajax_save', { timestamp: timestamp, data: items }, function(response) {
      console.log(response);
      if (response == 'invalid') {
        location.reload(true);
      } else {
        timestamp = response.timestamp;
      }
      saving = false;
      $('.ajax_load').hide();
    });

    console.log("Saving");

    if (callback instanceof Function) callback();
  }

  $('.todo_item input:checkbox').live('click', function(event) {
    if (saving) {
      event.preventDefault();
      return;
    }

    var pos = $(this).position();
    var checked = $(this).attr('checked');

    save(function() {
      var icon = $('<img class="smile" src="/images/icons/' + (checked ? 'happy' : 'sad') + '.png" />');
      $('body').append(icon);
      console.log($(icon).width());
      $(icon).css({ position: 'absolute',
                    left: pos.left-15,
                    top: pos.top });


      setTimeout(function() {
        $(icon).remove();
      }, 500);
          
    });
  });

  $('.todo_item .description').live('click', function() {
    if (saving) return;

    console.log('rah');
    var input = $("<input type='text' value='" + $(this).text() + "'></input>");
    $(this).replaceWith(input);
    $(input).focus();

    $(input).blur(function() {
      var span = $("<span class='description'>" + $(this).val() + "</input>");
      $(this).replaceWith(span);
      save();
    });
  });
  $('.todo_item a.delete').live('click', function() {
    if (saving) return;
    if ($('#todo_list .todo_item').length == 1) return; // Don't permit deletion of final item.

    $(this).parent().remove();
    save();
  });

  $('#add_item').click(function() {
    var todo = $('.todo_item').first().clone();
    $('input:checkbox', todo).attr('checked', false);
    $('span.description', todo).text('New');
    $('#todo_list').append(todo);
    save();
  });
});
