/**
 * @constructor
 */
var PTDownloadView = function() {

    var init = function() {
        setTimeout(function() {
            window.location.reload();
        }, 10000);
    };
    init();

};

var ready = function() {
    if ($('body#preparing_download').length) {
        PearTree.view = new PTDownloadView();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
