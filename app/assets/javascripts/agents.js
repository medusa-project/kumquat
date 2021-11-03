/**
 * Encapsulates show-agent view.
 *
 * @constructor
 */
const DLAgentView = function() {

    const self = this;

    this.init = function() {
        self.attachEventListeners();
        self.layout();
    };

    this.attachEventListeners = function() {
        $('.pagination a').on('click', function() {
            $('#dl-agents')[0].scrollIntoView({behavior: "smooth", block: "start"});
        });
    };

    this.layout = function() {
        // http://suprb.com/apps/gridalicious/
        $('.dl-flex-results').gridalicious({ width: 260, selector: '.dl-object' });
    };

};

$(document).ready(function() {
    if ($('body#agents_show').length) {
        Application.view = new DLAgentView();
        Application.view.init();
    }
});
