/**
 * @constructor
 */
var PTAdminTasksView = function() {

    var TASKS_URL = $('input[name="pt-tasks-url"]').val();

    this.init = function() {
        new Application.FilterField();

        new TaskRefresher().start();

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

    var TaskRefresher = function() {

        var FREQUENCY = 5000;

        var refreshTimer;

        var refresh = function() {
            console.debug('Refreshing task list...');

            var current_page = $('.pagination li.active > a:first')
                .text().replace(/[/\D]/g, '');
            var start = (current_page - 1) * $('[name=pt-limit]').val();
            var url = TASKS_URL + '?start=' + start;

            $.ajax({
                url: url,
                data: $('form.pt-filter').serialize(),
                success: function (data) {
                    // this will be handled by index.js.erb
                }
            });
        };

        this.start = function() {
            refreshTimer = setInterval(refresh, FREQUENCY);
            refresh();
        };

        this.stop = function() {
            clearInterval(refreshTimer);
        }

    };

};

var ready = function() {
    if ($('body#admin_tasks').length) {
        Application.view = new PTAdminTasksView();
        Application.view.init();
    }
};

$(document).ready(ready);
