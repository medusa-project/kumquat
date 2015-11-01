/**
 * Handles the nav bar search accordion.
 *
 * @constructor
 */
var KQSearchPanel = function() {

    this.init = function() {
        $('button.kq-check-all').on('click', function() {
            $(this).closest('.kq-collections').find('input[type="checkbox"]').
                prop('checked', true);
        });
        $('button.kq-uncheck-all').on('click', function() {
            $(this).closest('.kq-collections').find('input[type="checkbox"]').
                prop('checked', false);
        });
    };

};

var ready = function() {
    if ($('#kq-search-accordion').length) {
        var panel = new KQSearchPanel();
        panel.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
