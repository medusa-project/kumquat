var PTTaskRefresher = function() {

    var FREQUENCY = 4000;

    var self = this;

    var refresh = function() {
        console.log('Refreshing task list...');

        var tasks_url = $('input[name="pt-tasks-url"]').val();
        $.get(tasks_url, function (data) {
            $('#pt-tasks-list').html(data);
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

var teardown = function() {
    task_refresher.stop();
};

$(document).ready(ready);
$(document).on('page:load', ready);
$(document).on('page:before-change', teardown);
