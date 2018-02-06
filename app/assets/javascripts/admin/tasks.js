/**
 * @constructor
 */
var PTAdminTasksView = function() {

    var TASKS_URL = $('input[name="pt-tasks-url"]').val();

    this.init = function() {
        new Application.FilterField();

        $('#pt-task-panel').on('show.bs.modal', function(event) {
            var modal = $(this);
            var button = $(event.relatedTarget);
            var task_id = button.data('task-id');

            $.ajax({
                url: TASKS_URL + '/' + task_id,
                success: function (data) {
                    modal.find('.modal-body').html(data);
                },
                error: function(a, b, c) {
                    console.error(a);
                    console.error(b);
                    console.error(c);
                }
            });
        });
    };

};

var ready = function() {
    if ($('body#admin_tasks').length) {
        Application.view = new PTAdminTasksView();
        Application.view.init();
    }
};

$(document).ready(ready);
