// Overloads the repair button on the host edit/create page with a call to a modal dialog
$(initialize_repair_dialog);
function initialize_repair_dialog(){
  if ($("#host_managed").val() == "0") {
    $("#conflicts").button("option", "disabled", true)
    return false;
  }
  $("#conflicts").button("option", "disabled", false)

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
    $($(":button", $("#conflicts-content").parent())[0]).button("option","disabled", false)
    $('#conflicts-content').load($(this).attr('href'), set_repair_button);
    dialog.dialog("open");
    return false;
  })
}
function set_repair_button(){
  if ($("#no-issues").length == 1){
    $($(":button", $("#conflicts-content").parent())[0]).button("option", "disabled", true)
  }
}
