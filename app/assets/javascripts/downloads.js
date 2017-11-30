/**
 * @constructor
 */
var PTDownloadView = function() {

    var REFRESH_INTERVAL = 6000;

    var init = function() {
        setInterval(function() {
            console.debug('Refreshing...');
            $.ajax({
                url: window.location,
                method: 'GET',
                data: null,
                dataType: 'script',
                success: function(result) {
                    $('pt-download-status').html(result);
                }
            });
        }, REFRESH_INTERVAL);
    };
    init();

};

var ready = function() {
    if ($('body#download_status').length) {
        Application.view = new PTDownloadView();
    }
};

$(document).ready(ready);
