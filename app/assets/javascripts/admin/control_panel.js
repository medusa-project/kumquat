/**
 * A control panel object available in all Control Panel views as
 * Kumquat.ControlPanel.
 *
 * @constructor
 */
var KQControlPanel = function() {

    this.init = function() {
        // The X-Kumquat-Message and X-Kumquat-Message-Type headers are set by
        // an ApplicationController after_action to support ajax requests.
        // X-Kumquat-Result is another header that, if set, can contain
        // "success" or "error", indicating the result of a form submission.
        $(document).ajaxComplete(function(event, request, options) {
            console.log('ajaxComplete');
            //$('#kq-ajax-shade').hide();
        });

        $(document).ajaxSuccess(function(event, request) {
            var result = request.getResponseHeader('X-Kumquat-Result');
            console.log('X-Kumquat-Result: ' + result);
            if (result) {
                var edit_panel = $('.kq-edit-panel.in');
                if (edit_panel.length) {
                    if (result == 'success') {
                        edit_panel.modal('hide');
                    } else if (result == 'error') {
                        edit_panel.find('.modal-body').animate({scrollTop: 0}, 'fast');
                    }
                    var message = request.getResponseHeader('X-Kumquat-Message');
                    var message_type = request.getResponseHeader('X-Kumquat-Message-Type');
                    if (message && message_type) {
                        Kumquat.Flash.set(message, message_type);
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
    Kumquat.ControlPanel = new KQControlPanel();
    Kumquat.ControlPanel.init();
};

$(document).ready(ready);
$(document).on('page:load', ready);
