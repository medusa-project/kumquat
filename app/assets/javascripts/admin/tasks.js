var PTTaskRefresher = function() {

    var FREQUENCY = 4000;

    var self = this;

    var refresh = function() {
        console.log('Refreshing task list...');

        var tasks_url = $('input[name="pt-tasks-url"]').val();
        $.get(tasks_url, function (data) {
            var tasks_list = $('#pt-tasks-list');
            tasks_list.html(data);

            // If we are in show-task view, get the ID of the task being viewed
            // and update the info in the show pane from the tasks list.
            var task_id = $('input[name=pt-task-id]').val();

            var task_row = tasks_list.find('tr[data-id=' + task_id + ']');
            var title = task_row.find('.pt-title').text();
            var status = task_row.find('.pt-status').html();
            var progress = task_row.find('.pt-progress').text();
            var started = task_row.find('.pt-started').clone();

            $('h1.pt-title').text(title);
            $('dd.pt-status').html(status);
            $('dd.pt-progress').text(progress);
            $('dd.pt-started').empty().append(started);
            LocalTime.run(); // from the local_time gem
        });
    };

    this.refreshTimer = null;

    this.start = function() {
        self.refreshTimer = setInterval(refresh, FREQUENCY);
        refresh();
    };

    this.stop = function() {
        clearInterval(self.refreshTimer);
    }

};

var task_refresher;

var ready = function() {
    if ($('body#admin_tasks, body#admin_task_show').length) {
        task_refresher = new PTTaskRefresher();
        task_refresher.start();
    }
};

$(document).ready(ready);
