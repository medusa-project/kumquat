/**
 * The Batch Change modal is used in a couple of different views.
 *
 * @constructor
 */
var BatchChangeModal = function() {

    this.init = function() {
        $('button.dl-add-element').on('click', function() {
            var element = $(this).closest('.dl-elements').find('.dl-element:last-child');
            var clone = element.clone(true);
            clone.find('input').val('');
            element.after(clone);
            return false;
        });
        $('button.dl-remove-element').on('click', function() {
            var element = $(this).closest('.dl-element');
            if (element.siblings().length > 0) {
                element.remove();
            }
            return false;
        });
    };

};

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
            $('.dl-autocomplete-results').remove();
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
            var div = '<div class="dl-autocomplete-results">' +
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
        new Application.DirtyFormListener('form').listen();

        new BatchChangeModal().init();

        // Auto-vertical-resize the textareas...
        var textareas = $('#dl-metadata textarea');
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
        textareas.on('propertychange keyup change', function() {
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

    var self = this;
    var shade = new Application.AJAXShade();

    this.init = function() {
        self.attachEventListeners();
    };

    this.attachEventListeners = function() {
        new Application.DirtyFormListener('form').listen();

        $('.pagination a').off().on('click', function() {
            $('#dl-items')[0].scrollIntoView({behavior: "smooth", block: "start"});
        });

        // Make the table header stick to the top when scrolling. (DLD-124)
        // Uses jquery.stickytableheaders.min.js
        // https://github.com/jmosbech/StickyTableHeaders
        $('table').stickyTableHeaders({
            cacheHeaderHeight: true
        });

        // When the form is dirty and a link is clicked, prompt to save changes
        // before proceeding.
        $('a').off().on('click', function() {
            if ($('.dl-dirty').length) {
                return window.confirm('Proceed without saving changes?');
            }
        });

        // Intercept submit button clicks to POST via AJAX. Otherwise, page 1
        // will be loaded upon form submission.
        $('input[type=submit]').off().on('click', function(e) {
            e.preventDefault();

            shade.show();

            var collection_id = $('input[name=dl-collection-id]').val();
            $.ajax({
                type: 'POST',
                url: '/admin/collections/' + collection_id + '/items/update',
                data: $("form").serialize(),
                success: function(result) {
                    $('input[type=number], textarea').removeClass('dl-dirty');
                },
                error: function(xhr, status, error) {
                    console.error(error);
                    console.error(xhr);
                    console.error(status);
                    alert('Error: ' + error);
                },
                complete: function(result) {
                    shade.hide();
                }
            });
        });
    };

};

/**
 * Manages item results view.
 *
 * @constructor
 */
var PTAdminItemsView = function() {

    var self = this;

    this.init = function() {
        new Application.FilterField();
        Application.initFacets();

        new BatchChangeModal().init();

        self.attachEventListeners();
    };

    this.attachEventListeners = function() {
        $('.pagination a').on('click', function() {
            $('form.dl-filter')[0].scrollIntoView({behavior: "smooth", block: "start"});
        });

        $('#dl-export-modal button[type=submit]').on('click', function() {
            $('#dl-export-modal').modal('hide');
        });

        // Enable certain checkboxes in the import panel only when the "create"
        // radio is selected.
        var extract_metadata_checkbox = $('input[name="options[extract_metadata]"]');
        var extract_creation_checkbox = $('input[name="options[include_date_created]"]');
        $('input[name="ingest_mode"]').on('change', function() {
            extract_metadata_checkbox.prop('disabled',
                !$('input[value="create_only"]').prop('checked'));
            extract_creation_checkbox.prop('disabled',
                !$('input[value="create_only"]').prop('checked'));
        });

        // When the add-checked-items-to-set modal is shown, copy the selected
        // item IDs in the results into hidden inputs in the modal form.
        $('#dl-add-checked-items-to-set-modal').on('shown.bs.modal', function() {
            var modal_body = $(this).find('.modal-body');
            modal_body.find('[name="items[]"]').remove();

            var checked_items = [];
            $('[name="dl-selected-items[]"]:checked').each(function() {
                checked_items.push($(this).val());
            });
            for (var i = 0; i < checked_items.length; i++) {
                modal_body.append('<input type="hidden" name="items[]" value="' + checked_items[i] + '">');
            }
        });

        // When the "Publish Checked Results" or "Unpublish Checked Results"
        // menu items are clicked, copy the selected item IDs into their hrefs.
        $('#dl-publish-checked-results-link, #dl-unpublish-checked-results-link').on('click', function() {
            var checked_items = [];
            $('[name="dl-selected-items[]"]:checked').each(function() {
                checked_items.push($(this).val());
            });

            var href = $(this).attr('href');
            var pos = href.indexOf('?');
            var url = (pos > 0) ? href.substring(0, pos) : href;
            $(this).attr('href', url + '?id[]=' + checked_items.join('&id[]='));
        });
    };

};

var PTAdminItemView = function() {
    this.init = function() {
        $('[data-toggle=popover]').popover({ 'html' : true });
    }
};

var ready = function() {
    if ($('body#admin_items_edit').length) {
        Application.view = new PTAdminItemEditView();
        Application.view.init();
    } else if ($('body#admin_items_edit_all').length) {
        Application.view = new PTAdminItemsEditView();
        Application.view.init();
    } else if ($('body#admin_items_index').length) {
        Application.view = new PTAdminItemsView();
        Application.view.init();
    } else if ($('body#admin_items_show').length) {
        Application.view = new PTAdminItemView();
        Application.view.init();
    }
};

$(document).ready(ready);
