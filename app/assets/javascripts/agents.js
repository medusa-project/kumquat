/**
 * Encapsulates show-agent view.
 *
 * @constructor
 */
var PTAgentView = function() {

    var self = this;

    this.init = function() {
        self.attachEventListeners();
        self.layout();
    };

    this.attachEventListeners = function() {
        $('.pagination a').on('click', function() {
            $('#pt-agents')[0].scrollIntoView({behavior: "smooth", block: "start"});
        });
    };

    this.layout = function() {
        // http://suprb.com/apps/gridalicious/
        $('.pt-flex-results').gridalicious({ width: 260, selector: '.pt-object' });
    };

};

var ready = function() {
    if ($('body#agents_show').length) {
        Application.view = new PTAgentView();
        Application.view.init();
    }
};

$(document).ready(ready);
