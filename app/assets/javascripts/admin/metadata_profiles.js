/**
 * @constructor
 */
var AdminMetadataProfilesView = function() {

    this.init = function() {
        $('button.kq-edit-triple').on('click', function() {
            var triple_id = $(this).data('triple-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url = ROOT_URL + '/admin/triples/' + triple_id + '/edit';
            $.get(url, function(data) {
                $('#kq-edit-triple-modal .modal-body').html(data);
            });
        });
    };

};

var ready = function() {
    if ($('body#metadata_profiles_show').length) {
        Kumquat.view = new AdminMetadataProfilesView();
        Kumquat.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
