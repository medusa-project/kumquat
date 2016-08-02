// The X-PearTree-Message and X-PearTree-Message-Type headers are set by an
// ApplicationController after_filter to support ajax requests.
// X-PearTree-Result is another header that, if set, can contain "success" or
// "error", indicating the result of a form submission.

$(document).ajaxComplete(function(event, request, options) {
    $('#pt-ajax-shade').hide();
});

$(document).ajaxSuccess(function(event, request) {
    var result_type = request.getResponseHeader('X-PearTree-Message-Type');
    var edit_panel = $('.pt-edit-panel.in');

    if (result_type && edit_panel.length) {
        if (result_type == 'success') {
            edit_panel.modal('hide');
        } else if (result_type == 'error') {
            edit_panel.find('.modal-body').animate({ scrollTop: 0 }, 'fast');
        }
        var message = request.getResponseHeader('X-PearTree-Message');
        if (message && result_type) {
            PearTree.Flash.set(message, result_type);
        }
    }
});

$(document).ajaxError(function(event, request, settings) {
    console.error(event);
    console.error(request);
    console.error(settings);
});
