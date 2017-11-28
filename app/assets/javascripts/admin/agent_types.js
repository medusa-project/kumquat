/**
 * @constructor
 */
var PTAdminAgentTypesView = function() {

    this.init = function() {
        $('button.pt-edit-agent-type').on('click', function() {
            var type_id = $(this).data('agent-type-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url = ROOT_URL + '/admin/agent-types/' + type_id + '/edit';
            $.get(url, function(data) {
                $('#pt-edit-agent-type-modal .modal-body').html(data);
            });
        });
        $('a[disabled="disabled"]').on('click', function() { return false; });
    };

};

var ready = function() {
    if ($('body#admin_agent_types_index').length) {
        PearTree.view = new PTAdminAgentTypesView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
