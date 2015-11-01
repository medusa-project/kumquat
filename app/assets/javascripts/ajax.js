// The X-Kumquat-Message and X-Kumquat-Message-Type headers are set by an
// ApplicationController after_filter to support ajax requests.
// X-Kumquat-Result is another header that, if set, can contain "success" or
// "error", indicating the result of a form submission.

$(document).ajaxComplete(function(event, request, options) {
    $('#kq-ajax-shade').hide();
});

$(document).ajaxSuccess(function(event, request) {
    var result_type = request.getResponseHeader('X-Kumquat-Message-Type');
    var edit_panel = $('.kq-edit-panel.in');

    if (result_type && edit_panel.length) {
        if (result_type == 'success') {
            edit_panel.modal('hide');
        } else if (result_type == 'error') {
            edit_panel.find('.modal-body').animate({ scrollTop: 0 }, 'fast');
        }
        var message = request.getResponseHeader('X-Kumquat-Message');
        if (message && result_type) {
            Kumquat.Flash.set(message, result_type);
        }
    }
});

$(document).ajaxError(function(event, request) {
    console.log('ajaxError');
});
