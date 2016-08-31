/**
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
                    '/terms.json?query=' + query +
                    '&type=' + inputType;
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
        var textareas = $('textarea');
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

        // Show the "extract metadata" checkbox in the sync panel only when the
        // "create" radio is selected.
        var extract_metadata_checkbox = $('input[name="options[extract_metadata]"]');
        $('input[name="ingest_mode"]').on('change', function() {
            extract_metadata_checkbox.prop('disabled',
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
