var PTServerStatusMonitor = function() {

    var refresh_timer;

    var refresh = function() {
        console.log('Refreshing server status...');
        $('.pt-dynamic-status').each(function() {
            var status = $(this).find('.pt-service-status:first');
            var check_url = status.attr('data-check');
            $.ajax({
                url: check_url,
                data: {},
                complete: function(xhr) {
                    if (xhr.status == 200) {
                        status.addClass('label-success').
                            removeClass('label-danger hidden').
                            text('Online');
                    }
                },
                error: function(xhr, statusText, err) {
                    status.addClass('label-danger').
                        removeClass('label-success hidden').
                        text('Offline');
                }
            });
        });
    };

    this.start = function() {
        refresh();
        refresh_timer = setInterval(refresh, 8000);
    };

    this.stop = function() {
        console.log('Clearing server status refresh timer');
        clearInterval(refresh_timer);
    };

};

var monitor;

var ready = function() {
    if ($('body#status').length) {
        monitor = new PTServerStatusMonitor();
        monitor.start();
    }
};

var teardown = function() {
    if ($('body#status').length && monitor) {
        monitor.stop();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
$(document).on('page:before-change', teardown);
