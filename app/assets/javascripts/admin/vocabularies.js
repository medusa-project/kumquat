/**
 * @constructor
 */
const DLAdminVocabularyView = function() {

    const init = function() {
        $('button#dl-delete-checked').on('click', function() {
            $(this).parents('form').submit();
        });

        $('button.dl-edit-term').on('click', function() {
            const ROOT_URL = $('input[name="root_url"]').val();
            const vocab_id = $(this).data('vocabulary-id');
            const term_id  = $(this).data('term-id');
            const url      = ROOT_URL + '/admin/vocabularies/' + vocab_id +
                '/terms/' + term_id + '/edit';
            $.get(url, function(data) {
                $('#dl-edit-term-modal .modal-body').html(data);
            });
        });
    }; init();

};

$(document).ready(function() {
    if ($('body#vocabularies_show').length) {
        Application.view = new DLAdminVocabularyView();
    }
});
