/**
 * @constructor
 */
const DLDownloadView = function() {

    const REFRESH_INTERVAL = 6000;

    const init = function() {
        setInterval(function() {
            console.debug('Refreshing...');
            $.ajax({
                url: window.location,
                method: 'GET',
                data: null,
                dataType: 'script',
                success: function(result) {
                    $('dl-download-status').html(result);
                }
            });
        }, REFRESH_INTERVAL);
    };
    init();

};

$(document).ready(function() {
    if ($('body#download_status').length) {
        Application.view = new DLDownloadView();
    }
});
