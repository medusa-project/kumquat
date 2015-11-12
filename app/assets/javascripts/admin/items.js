/**
 * @constructor
 */
var PTAdminItemsView = function() {

    var ELEMENT_LIMIT = 4;

    this.init = function() {
        $('button.pt-add-triple').on('click', function() {
            // limit to ELEMENT_LIMIT fields
            if ($('.pt-triples .form-group').length < ELEMENT_LIMIT) {
                var clone = $(this).prev('.form-group').clone(true);
                $(this).before(clone);
            }
        });
        $('button.pt-remove-element').on('click', function() {
            if ($('.kq-elements .form-group').length > 1) {
                $(this).closest('.form-group').remove();
            }
        });

        $('button.pt-check-all').on('click', function() {
            $(this).parent().find('.pt-collections').
                find('input[type="checkbox"]').prop('checked', true);
        });
        $('button.pt-uncheck-all').on('click', function() {
            $(this).parent().find('.pt-collections').
                find('input[type="checkbox"]').prop('checked', false);
        });
    };

};

var ready = function() {
    if ($('body#items_index').length) {
        PearTree.view = new PTAdminItemsView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
