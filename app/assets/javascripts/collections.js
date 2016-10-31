/**
 * Represents collection list view.
 *
 * @constructor
 */
var PTCollectionsView = function() {

    this.init = function() {
        $('[name=pt-facet-term]').on('change', function() {
            if ($(this).prop('checked')) {
                window.location = $(this).data('checked-href');
            } else {
                window.location = $(this).data('unchecked-href');
            }
        });

        // IMET-404: Get a list of checked repositories...
        var repositories = [];
        $('#pt-repository-facet input:checked').each(function() {
            repositories.push($(this).next().text().trim());
        });
        // ... and then set the page subtitle to the English-ized list.
        if (repositories.length > 0) {
            var html = '<h2>';
            if (repositories.length == 1) {
                html += repositories[0];
            } else {
                var last = repositories.pop();
                var others = repositories.join(', ');
                html += others + ' and ' + last;
            }
            html += '</h2>';
            $('.pt-cards').prepend(html);
        }
    };

};

var ready = function() {
    if ($('body#collections_index').length) {
        PearTree.view = new PTCollectionsView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
