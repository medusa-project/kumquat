var PTTaskRefresher = function() {

    var FREQUENCY = 4000;

    var self = this;

    var refresh = function () {
        console.log('Refreshing task list...');

        var tasks_url = $('input[name="tasks-url"]').val();
        $.get(tasks_url, function (data) {
            $('#pt-tasks-list').html(data);
            $('[data-toggle=popover]').popover({ container: 'body', html: true });

            // We need to handle opover-closing specially due to the way the
            // tasks table auto-refreshes.
            $('body').on('click', function (e) {
                // If the user did not click a popover toggle or popover...
                if ($(e.target).data('toggle') !== 'popover'
                    && $(e.target).parents('.popover.in').length === 0) {
                    // Close all popovers...
                    $('[data-toggle="popover"]').popover('hide');
                    // and destroy any remaining zombie popovers.
                    $('.popover.in').fadeOut(function() { $(this).remove() });
                }
            });
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
