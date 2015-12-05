$(function() {
  $('#select_timesheet_period_type_2').click(function() {
    $('#timesheet_period_type_2').attr('checked','checked')
  })

  $('#select_timesheet_period_type_1').focus(function() {
    $('#timesheet_period_type_1').attr('checked','checked')
  })

	$("label.select-all").click(function () {
		var select = $(this).siblings("select")
		var options = select.children()
		var selected = options.length != select.find(":selected").length
		options.each(function (index, ele) { ele.selected = selected });
	})
})