/**
 * Represents collection list view.
 *
 * @constructor
 */
var PTCollectionsView = function() {

    var init = function() {
        new PearTree.FilterField();

        var addFacetEventListeners = function() {
            $('[name="pt-facet-term"]').on('change', function() {
                // Create hidden element counterparts of each checked checkbox,
                // as checkboxes can't have values.
                var form = $(this).parents('form:first');
                form.find('[name="fq[]"]').remove();
                form.find('[name=pt-facet-term]:checked').each(function() {
                    var input = $('<input type="hidden" name="fq[]">');
                    input.val($(this).data('query'));
                    form.append(input);
                });

                $.ajax({
                    url: '/collections?',
                    method: 'GET',
                    data: form.serialize(),
                    dataType: 'script',
                    success: function(result) {
                        eval(result);
                    }
                });

                // IMET-404: Get a list of checked repositories...
                var repositories = [];
                $('#pt-repository-facet input:checked').each(function() {
                    repositories.push($(this).next().text().trim());
                });
                // ... and then set the page title to the English-ized list.
                var text = '';
                var count = $('#pt-count');
                if (repositories.length == 1) {
                    text += repositories[0];
                } else if (repositories.length > 1) {
                    var last = repositories.pop();
                    var others = repositories.join(', ');
                    text += others + ' and ' + last;
                } else {
                    text = 'Collections';
                }
                $('#pt-page-title').text(text + ' ');
                $('#pt-page-title').append(count);
            });
        };

        // When the filter field has been updated, it will recreate the facets.
        $(document).ajaxSuccess(function(event, request) {
            addFacetEventListeners();
        });
        addFacetEventListeners();
    }; init();
};

var ready = function() {
    if ($('body#collections_index').length) {
        PearTree.view = new PTCollectionsView();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
