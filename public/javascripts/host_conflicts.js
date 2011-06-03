// Overloads the conflicts button on the host edit/create page with a call to a modal dialog
$(initialize_conflicts_dialog);
function initialize_conflicts_dialog(){
  var waiting = 'Querying the network... <img src="/images/spinner.gif">';
  var dialog  = $('<div id=conflicts-content>' + waiting + '</div>').appendTo('body').dialog({
    title:    "Network database issues",
    height:   600,
    width:    600,
    modal:    true,
    autoOpen: false,
    close:    function(){
      $("#conflicts-content").html(waiting)},
    buttons: [
      {
        text: "Remove all conflicts and add missing entries",
        click: function() {
          $.ajax({url:      $("form[action$='repair']").attr('action'),
                  data:     $("form[action$='repair']").serialize(),
                  complete: $(this).dialog("close"),
                  error:    function() {alert('This operation failed. Please inspect the logs on the foreman server')},
                  success:  function() {alert('The repair operation completed successfully')}
                });

        }
      },
      {
        text: "Cancel",
        click: function() {
          $(this).dialog("close");
        }
      }
    ]
  });

  $("#conflicts").button().click(function() {
    $($(":button", $("#conflicts-content").parent())[0]).removeClass("ui-state-disabled").attr("disabled", false)
    $('#conflicts-content').load($(this).attr('href'), set_repair_button);
    dialog.dialog("open");
    return false;
  })
}
function set_repair_button(){
  if ($("#no-issues").length == 1){
    $($(":button", $("#conflicts-content").parent())[0]).addClass("ui-state-disabled").attr("disabled", true)
  }
}
