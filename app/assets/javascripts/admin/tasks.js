var PTTaskRefresher = function() {

    var FREQUENCY = 4000;

    var self = this;

    var refresh = function () {
        console.log('Refreshing task list...');

        var tasks_url = $('input[name="tasks-url"]').val();
        $.get(tasks_url, function (data) {
            $('#pt-tasks-list').html(data);
            console.log('Refreshed task list');
        });
    };

    this.refreshTimer = null;

    this.start = function () {
        self.refreshTimer = setInterval(refresh, FREQUENCY);
        refresh();
    };

};

var task_refresher;

var ready = function() {
    if ($('body#tasks').length) {
        task_refresher = new PTTaskRefresher();
        task_refresher.start();
    }
};

var teardown = function() {
    clearInterval(task_refresher.refreshTimer);
};

$(document).ready(ready);
$(document).on('page:load', ready);
$(document).on('page:before-change', teardown);
