/**
 * Handles the nav bar search accordion.
 *
 * @constructor
 */
var PTSearchPanel = function() {

    this.init = function() {
        $('button.pt-check-all').on('click', function() {
            $(this).closest('.pt-collections').find('input[type="checkbox"]').
                prop('checked', true);
        });
        $('button.pt-uncheck-all').on('click', function() {
            $(this).closest('.pt-collections').find('input[type="checkbox"]').
                prop('checked', false);
        });
    };

};

var ready = function() {
    if ($('#pt-search-accordion').length) {
        var panel = new PTSearchPanel();
        panel.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
