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
        var textareas = $('#pt-metadata textarea');
        var MAGIC_FUDGE = 12;
        var MIN_HEIGHT = 20;
        // ... initially
        textareas.each(function() {
            $(this).height('0px');
            var height = this.scrollHeight - MAGIC_FUDGE;
            height = (height < MIN_HEIGHT) ? MIN_HEIGHT : height;
            $(this).height(height + 'px');
        });
        // ... and on change
        textareas.on('input propertychange keyup change', function() {
            $(this).height('20px');
            $(this).height((this.scrollHeight - MAGIC_FUDGE) + 'px');
        });

        // When a controlled term select menu item is selected, select the
        // corresponding string or URI in its counterpart menu,
        $('#pt-metadata').find('select').on('change', function() {
            // Find the index of the selected option, and then set the
            // counterpart menu's selection to the same.
            var selectedIndex = $(this).prop('selectedIndex');
            if ($(this).data('type') == 'string') {
                var uriSelectName = $(this).attr('name').replace('[string]', '[uri]');
                $('[name="' + uriSelectName + '"] option:nth-child(' + (selectedIndex + 1) + ')').
                        prop('selected', 'selected');
            } else {
                var stringSelectName = $(this).attr('name').replace('[uri]', '[string]');
                $('[name="' + stringSelectName + '"] option:nth-child(' + (selectedIndex + 1) + ')').
                        prop('selected', 'selected');
            }
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

        // Enable certain checkboxes in the sync panel only when the "create"
        // radio is selected.
        var extract_metadata_checkbox = $('input[name="options[extract_metadata]"]');
        var extract_creation_checkbox = $('input[name="options[include_date_created]"]');
        $('input[name="ingest_mode"]').on('change', function() {
            extract_metadata_checkbox.prop('disabled',
                !$('input[value="create_only"]').prop('checked'));
            extract_creation_checkbox.prop('disabled',
                !$('input[value="create_only"]').prop('checked'));
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
