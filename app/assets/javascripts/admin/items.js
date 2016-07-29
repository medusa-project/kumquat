/**
 * @constructor
 */
var PTAdminItemEditView = function() {

    this.init = function() {
        $('button.pt-add-element').on('click', function() {
            var element = $(this).closest('.pt-element');

            var clone = element.clone(true);
            clone.find('input').val('');

            element.after(clone);

            return false;
        });
        $('button.pt-remove-element').on('click', function() {
            var element = $(this).closest('.pt-element');
            if (element.siblings().length > 0) {
                element.remove();
            }
            return false;
        });

        // Auto-vertical-resize the textareas...
        var textareas = $('textarea');
        var MAGIC_FUDGE = 12;
        // ... initially
        textareas.each(function() {
            $(this).height('0px');
            $(this).height((this.scrollHeight - MAGIC_FUDGE) + 'px');
        });
        // ... and on change
        textareas.on('input propertychange keyup change', function() {
            $(this).height('20px');
            $(this).height((this.scrollHeight - MAGIC_FUDGE) + 'px');
        });
    };

};

/**
 * @constructor
 */
var PTAdminItemsView = function() {

    var ELEMENT_LIMIT = 4;

    this.init = function() {
        $('button.pt-add-element').on('click', function() {
            // limit to ELEMENT_LIMIT fields
            if ($('.pt-elements .form-group').length < ELEMENT_LIMIT) {
                var clone = $(this).prev('.form-group').clone(true);
                $(this).before(clone);
            }
        });
        $('button.pt-remove-element').on('click', function() {
            if ($('.pt-elements .form-group').length > 1) {
                $(this).closest('.form-group').remove();
            }
        });
    };

};

var ready = function() {
    if ($('body#items_edit').length) {
        PearTree.view = new PTAdminItemEditView();
        PearTree.view.init();
    }
    if ($('body#items_index').length) {
        PearTree.view = new PTAdminItemsView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
