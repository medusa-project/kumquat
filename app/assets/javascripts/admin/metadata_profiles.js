/**
 * @constructor
 */
var PTAdminMetadataProfileView = function() {

    var init = function() {
        $('button#pt-delete-checked').on('click', function() {
            $(this).parents('form').submit();
        });

        $('button.pt-edit-element').on('click', function() {
            var element_id = $(this).data('element-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url = ROOT_URL + '/admin/metadata_profile_elements/' + element_id + '/edit';
            $.get(url, function(data) {
                $('#pt-edit-element-modal .modal-body').html(data);
            });
        });
    }; init();

};

var ready = function() {
    if ($('body#metadata_profiles_show').length) {
        Application.view = new PTAdminMetadataProfileView();
    }
};

$(document).ready(ready);
