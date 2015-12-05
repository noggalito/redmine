function selectAllOptions(id) {
  var select = $('#'+id);
  select.children('option').attr('selected', true);
}

function submit_query_form(id) {
  selectAllOptions("selected_columns");
  $('#'+id).submit();
}
