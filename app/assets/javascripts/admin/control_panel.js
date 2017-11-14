/**
 * A control panel object available in all Control Panel views as
 * PearTree.ControlPanel.
 *
 * @constructor
 */
var PTControlPanel = function() {

    this.init = function() {
        // Save the last-clicked tab in a cookie.
        $('a[data-toggle="tab"]').on('click', function(e) {
            Cookies.set('last_tab', $(e.target).attr('href'));
        });

        // Activate the latest tab, if it exists.
        var last_tab = Cookies.get('last_tab');
        if (last_tab) {
            $('a[href="' + last_tab + '"]').click();
        }
    };

};

var ready = function() {
    PearTree.ControlPanel = new PTControlPanel();
    PearTree.ControlPanel.init();
};

$(document).ready(ready);
$(document).on('page:load', ready);
