/**
 * @constructor
 */
var AdminItemsView = function() {

    var TRIPLE_LIMIT = 4;

    this.init = function() {
        $('button.kq-add-triple').on('click', function() {
            // limit to TRIPLE_LIMIT fields
            if ($('.kq-triples .form-group').length < TRIPLE_LIMIT) {
                var clone = $(this).prev('.form-group').clone(true);
                $(this).before(clone);
            }
        });
        $('button.kq-remove-triple').on('click', function() {
            if ($('.kq-triples .form-group').length > 1) {
                $(this).closest('.form-group').remove();
            }
        });

        $('button.kq-check-all').on('click', function() {
            $(this).parent().find('.kq-collections').
                find('input[type="checkbox"]').prop('checked', true);
        });
        $('button.kq-uncheck-all').on('click', function() {
            $(this).parent().find('.kq-collections').
                find('input[type="checkbox"]').prop('checked', false);
        });
    };

};

var ready = function() {
    if ($('body#items_index').length) {
        Kumquat.view = new AdminItemsView();
        Kumquat.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
