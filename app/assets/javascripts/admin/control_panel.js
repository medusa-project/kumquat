/**
 * A control panel object available in all Control Panel views as
 * Application.ControlPanel.
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

        // If the URL has a fragment, select the corresponding tab.
        if (window.location.hash) {
            $('a[href="' + window.location.hash + '"]').click();
            // Scroll the page to the top. Have to do this on a timer because
            // the tab-showing triggered by the above click is asynchronous.
            setTimeout(function() {
                document.body.scrollTop = document.documentElement.scrollTop = 0;
            }, 50);
        }
    };

};

var ready = function() {
    Application.ControlPanel = new PTControlPanel();
    Application.ControlPanel.init();
};

$(document).ready(ready);
