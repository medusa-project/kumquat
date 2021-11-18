/**
 * @constructor
 */
const DLAdminElementsView = function() {

    this.init = function() {
        $('button.dl-edit-element').on('click', function() {
            var element_id = $(this).data('element-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url = ROOT_URL + '/admin/elements/' + element_id + '/edit';
            $.get(url, function(data) {
                $('#dl-edit-element-modal .modal-body').html(data);
            });
        });
        $('a[disabled="disabled"]').on('click', function() { return false; });
    };

};

$(document).ready(function() {
    if ($('body#elements').length) {
        Application.view = new DLAdminElementsView();
        Application.view.init();
    }
});
