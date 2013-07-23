$(document).ready(function() {
  $("#synergy_table").tablesorter({
    headers: {
      0: { sorter: false },
      1: { sorter: false },
      5: { sorter: false }
    },
    sortList: [[3,1]]
  });

  function update_tier() {
    if ($('#tier').val() == 'all') {
      $('#nfe_container').show();
    } else {
      $('#nfe_container').hide();
    }
  }

  $('#tier').change(update_tier);
  update_tier();

  function update_gen() {
    var gen = parseInt($('#gen').val());
    console.log(gen);

    if ($('option.tier.gen' + gen + '[value=' + $('#tier').val() + ']').length == 0) {
      $('#tier').val('all');
    }

    if (gen >= 4) {
      $('#tier_container').show();
      $('option.tier').hide();
      $('option.tier.gen' + gen).show();
      update_tier();
    } else {
      $('#nfe_container').show();
      $('#tier_container').hide();
    }
  }

  $('#gen').change(update_gen);
  update_gen();
});
