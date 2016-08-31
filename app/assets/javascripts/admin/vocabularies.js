/**
 * @constructor
 */
var PTAdminVocabularyView = function() {

    var init = function() {
        $('button#pt-delete-checked').on('click', function() {
            $(this).parents('form').submit();
        });

        $('button.pt-edit-term').on('click', function() {
            var term_id = $(this).data('term-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url = ROOT_URL + '/admin/vocabulary-terms/' + term_id + '/edit';
            $.get(url, function(data) {
                $('#pt-edit-term-modal .modal-body').html(data);
            });
        });
    }; init();

};

var ready = function() {
    if ($('body#vocabularies_show').length) {
        PearTree.view = new PTAdminVocabularyView();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
