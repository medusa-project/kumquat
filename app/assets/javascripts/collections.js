/**
 * Represents collection list view.
 *
 * @constructor
 */
var PTCollectionsView = function() {

    var init = function() {
        new Application.FilterField();

        // When the filter field has been updated, it will recreate the facets.
        $(document).ajaxSuccess(function(event, request) {
            attachEventListeners();
            updateTitle();
        });
        attachEventListeners();
        updateTitle();
    }; init();

    function updateTitle() {
        // IMET-404: Get a list of checked repositories...
        var repositories = [];
        $('#dl-repository-facet input:checked').each(function() {
            repositories.push($(this).next().text().trim());
        });
        // ... and then set the page title to the English-ized list.
        var text = '';
        var count = $('#dl-count');
        if (repositories.length === 1) {
            text += repositories[0];
        } else if (repositories.length > 1) {
            var last = repositories.pop();
            var others = repositories.join(', ');
            text += others + ' and ' + last;
        } else {
            text = 'Collections';
        }
        var title = $('#dl-page-title');
        title.text(text + ' ');
        title.append(count);
    }

    function attachEventListeners() {
        $('.pagination a').off().on('click', function() {
            $('form.dl-filter')[0].scrollIntoView({behavior: "smooth", block: "start"});
        });

        $('[name="dl-facet-term"]').off().on('change', function() {
            // Create hidden element counterparts of each checked checkbox,
            // as checkboxes can't have values.
            var form = $(this).parents('form:first');
            form.find('[name="fq[]"]').remove();
            form.find('[name=dl-facet-term]:checked').each(function() {
                var input = $('<input type="hidden" name="fq[]">');
                input.val($(this).data('query'));
                form.append(input);
            });

            var query = form.serialize();

            window.history.pushState(
                { "html": null, "pageTitle": document.title },
                '', '/collections?' + query);

            console.debug("Requesting /collections?" + query);

            $.ajax({
                url: '/collections?',
                method: 'GET',
                data: query,
                dataType: 'script',
                success: function(result) {
                    eval(result);
                }
            });
        });
    };

};

var ready = function() {
    if ($('body#collections_index').length) {
        Application.view = new PTCollectionsView();
    }
};

$(document).ready(ready);
