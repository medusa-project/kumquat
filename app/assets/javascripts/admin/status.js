var PTServerStatusMonitor = function() {

    var REFRESH_INTERVAL = 8000;
    var refresh_timer;

    var refresh = function() {
        console.log('Refreshing server status...');

        var service_table = $('table#dl-status');
        var check_url = $('input[name=dl-status-url]').val();

        $.ajax({
            url: check_url,
            dataType: 'json',
            success: function(xhr, statusText) {
                service_table.empty();

                $.each(xhr, function(index, service) {
                    var row = '<tr>';
                    row += '<td>' + service.service + '</td>';
                    switch (service.status) {
                        case 'online':
                            row += '<td><span class="label label-success">Online</span></td>';
                            break;
                        default:
                            row += '<td><span class="label label-danger">Offline</span></td>';
                            break;
                    }
                    row += '</tr>';
                    service_table.append(row);
                });
            },
            error: function(xhr, statusText, e) {
                console.error(xhr);
                console.error(statusText);
                console.error(e);
            }
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

$(document).ready(ready);
