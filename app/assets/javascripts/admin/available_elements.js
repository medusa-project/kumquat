/**
 * @constructor
 */
var PTAdminAvailableElementsView = function() {

    this.init = function() {
        $('button.pt-edit-element').on('click', function() {
            var element_id = $(this).data('element-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url = ROOT_URL + '/admin/elements/' + element_id + '/edit';
            $.get(url, function(data) {
                $('#pt-edit-element-modal .modal-body').html(data);
            });
        });
        $('a[disabled="disabled"]').on('click', function() { return false; });
    };

};

var ready = function() {
    if ($('body#available_elements').length) {
        PearTree.view = new PTAdminAvailableElementsView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
