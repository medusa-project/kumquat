/**
 * A control panel object available in all Control Panel views as
 * PearTree.ControlPanel.
 *
 * @constructor
 */
var PTControlPanel = function() {

    this.init = function() {
        // The X-PearTree-Message and X-PearTree-Message-Type headers are set by
        // an ApplicationController after_action to support ajax requests.
        // X-PearTree-Result is another header that, if set, can contain
        // "success" or "error", indicating the result of a form submission.
        $(document).ajaxComplete(function(event, request, options) {
            console.log('ajaxComplete');
            //$('#pt-ajax-shade').hide();
        });

        $(document).ajaxSuccess(function(event, request) {
            var result = request.getResponseHeader('X-PearTree-Result');
            console.log('X-PearTree-Result: ' + result);
            if (result) {
                var edit_panel = $('.pt-edit-panel.in');
                if (edit_panel.length) {
                    if (result == 'success') {
                        edit_panel.modal('hide');
                    } else if (result == 'error') {
                        edit_panel.find('.modal-body').animate({scrollTop: 0}, 'fast');
                    }
                    var message = request.getResponseHeader('X-PearTree-Message');
                    var message_type = request.getResponseHeader('X-PearTree-Message-Type');
                    if (message && message_type) {
                        PearTree.Flash.set(message, message_type);
                    }
                }
            }
        });

        $(document).ajaxError(function(event, request) {
            console.log('ajaxError');
        });
    };

};

var ready = function() {
    PearTree.ControlPanel = new PTControlPanel();
    PearTree.ControlPanel.init();
};

$(document).ready(ready);
$(document).on('page:load', ready);
