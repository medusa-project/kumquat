var PTServerStatusMonitor = function() {

    var REFRESH_INTERVAL = 8000;
    var refresh_timer;

    var refresh = function() {
        console.log('Refreshing server status...');
        $('.pt-dynamic-status').each(function(index, el) {
            el = $(el);
            var status = el.find('.pt-service-status:first');
            var check_url = status.data('check');

            var showOffline = function() {
                status.addClass('label-danger')
                    .removeClass('label-success hidden')
                    .text('Offline');
            };

            $.ajax({
                url: check_url,
                data: {},
                success: function(xhr, statusText) {
                    if (xhr.status === 'online') {
                        status.addClass('label-success')
                            .removeClass('label-danger hidden')
                            .text('Online');

                        // Update various <dd> fields based on additional
                        // info returned in the JSON response.
                        var fields = el.find('dd');
                        $.each(fields.data(), function(k, v) {
                            fields.filter('[data-name=' + v + ']').text(xhr[v]);
                        });
                    } else {
                        showOffline();
                    }
                },
                error: function(xhr, statusText, err) {
                    showOffline();
                }
            });
        });
    };

    this.start = function() {
        refresh();
        refresh_timer = setInterval(refresh, REFRESH_INTERVAL);
    };

    this.stop = function() {
        console.log('Clearing server status refresh timer');
        clearInterval(refresh_timer);
    };

};

var monitor;

var ready = function() {
    if ($('body#admin_status').length) {
        monitor = new PTServerStatusMonitor();
        monitor.start();
    }
};

var teardown = function() {
    if ($('body#admin_status').length && monitor) {
        monitor.stop();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
$(document).on('page:before-change', teardown);
