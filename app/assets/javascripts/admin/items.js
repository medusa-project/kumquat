/**
 * Manages single-item edit view.
 *
 * @constructor
 */
var PTAdminItemEditView = function() {

    /**
     * @param input {jQuery}
     * @constructor
     */
    var Autocompleter = function(input) {
        var RESULTS_LIMIT = 10;
        var self = this;

        this.clearResults = function() {
            $('.pt-autocomplete-results').remove();
        };

        this.fetchResults = function(onSuccess) {
            var query = input.val();
            if (query.length > 1) {
                var vocabulary_id = input.data('vocabulary-id');
                var inputType = (input.attr('name').indexOf('[string]') > 0) ?
                    'string' : 'uri';
                var url = $('[name=root_url]').val() +
                    '/admin/vocabularies/' + vocabulary_id +
                    '/terms.json?query=' + query + '&type=' + inputType;
                console.debug('Autocompleter.fetchResults(): ' + url);
                $.ajax({
                    url: url,
                    success: function (results) {
                        onSuccess(results);
                    }
                });
            } else {
                self.clearResults();
            }
        };

        /**
         * @private
         */
        var init_ = function() {
            self.clearResults();

            self.fetchResults(function(results) {
                if (results.length > 0) {
                    self.renderResults(results);
                } else {
                    self.clearResults();
                }
            });
        }; init_();

        /**
         * Called publicly to complete initialization.
         */
        this.init = function() {
            $(':not([data-controlled=true])').on('click', function() {
                self.clearResults();
            });
        };

        this.renderResults = function(results) {
            var div = '<div class="pt-autocomplete-results">' +
                '<ul>';
            results.forEach(function (obj, index) {
                if (index < RESULTS_LIMIT) {
                    var value, type;
                    if (input.attr('name').indexOf('[string]') > 0) {
                        value = obj['string'];
                        type = 'string';
                    } else {
                        value = obj['uri'];
                        type = 'uri';
                    }
                    div += '<li><a href="#" data-type="' + type +
                        '" data-string="' + obj['string'] +
                        '" data-uri="' + obj['uri'] + '">' + value + '</a></li>';
                }
            });
            div += '</ul>' +
                '</div>';
            div = $(div);
            div.css('width', input.width());
            input.after(div);

            div.find('a').on('click', function() {
                if ($(this).data('type') == 'string') {
                    input.val($(this).data('string'));
                    input.parent().parent().next().find('input').val($(this).data('uri'));
                } else {
                    input.val($(this).data('uri'));
                    input.parent().parent().prev().find('input').val($(this).data('string'));
                }
                self.clearResults();
                return false;
            });

            div.find('li').on('mouseover', function() {
                $(this).addClass('active');
            }).on('mouseout', function() {
                $(this).removeClass('active');
            });
        };
    };

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

        // Initialize autocompletion for each controlled text field.
        $('[data-controlled=true]').on('input', function() {
            var ac = new Autocompleter($(this));
            ac.init();
        });
    };

};

/**
 * Manages multiple-item edit view.
 *
 * @constructor
 */
var PTAdminItemsEditView = function() {

    var ELEMENT_LIMIT = 4;

    var dirty = false;
    var self = this;

    this.init = function() {
        self.attachEventListeners();
    };

    this.attachEventListeners = function() {
        dirty = false;

        $('button.pt-add-element').off().on('click', function() {
            // limit to ELEMENT_LIMIT fields
            if ($(this).parents('.pt-elements').find('.form-group').length < ELEMENT_LIMIT) {
                var clone = $(this).prev('.form-group').clone(true);
                clone.val(null);
                $(this).before(clone);
            }
            return false;
        });
        $('button.pt-remove-element').off().on('click', function() {
            if ($(this).parents('.pt-elements').find('.form-group').length > 1) {
                $(this).closest('.form-group').remove();
            }
            return false;
        });

        // When a value is changed, mark the form as dirty.
        $('input[type=number], textarea').off().on('propertychange keyup change', function() {
            dirty = true;
            $(this).addClass('pt-dirty');
        });

        // When the form is dirty and a link is clicked, prompt to save changes
        // before proceeding.
        $('a').off().on('click', function() {
            if (dirty) {
                return window.confirm('Proceed without saving changes?');
            }
        });
    };

};

/**
 * @constructor
 */
var PTAdminItemsView = function() {

    this.init = function() {
        new PearTree.FilterField();
        PearTree.initFacets();

        $('#pt-export-modal button[type=submit]').on('click', function() {
            $('#pt-export-modal').modal('hide');
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

var PTAdminItemView = function() {
    this.init = function() {
        $('[data-toggle=popover]').popover({ 'html' : true });
    }
};

var ready = function() {
    if ($('body#items_edit').length) {
        PearTree.view = new PTAdminItemEditView();
        PearTree.view.init();
    } else if ($('body#items_edit_all').length) {
        PearTree.view = new PTAdminItemsEditView();
        PearTree.view.init();
    } else if ($('body#items_index').length) {
        PearTree.view = new PTAdminItemsView();
        PearTree.view.init();
    } else if ($('body#admin_items_show').length) {
        PearTree.view = new PTAdminItemView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
