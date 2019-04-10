/**
 * @constructor
 */
var PTAdminAgentRelationTypesView = function() {

    this.init = function() {
        $('button.dl-edit-agent-relation-type').on('click', function() {
            var type_id = $(this).data('agent-relation-type-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url = ROOT_URL + '/admin/agent-relation-types/' + type_id + '/edit';
            $.get(url, function(data) {
                $('#dl-edit-agent-relation-type-modal .modal-body').html(data);
            });
        });
        $('a[disabled="disabled"]').on('click', function() { return false; });
    };

};

var ready = function() {
    if ($('body#admin_agent_relation_types_index').length) {
        Application.view = new PTAdminAgentRelationTypesView();
        Application.view.init();
    }
};

$(document).ready(ready);
