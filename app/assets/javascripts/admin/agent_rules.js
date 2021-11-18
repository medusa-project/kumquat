/**
 * @constructor
 */
const DLAdminAgentRulesView = function() {

    this.init = function() {
        $('button.dl-edit-agent-rule').on('click', function() {
            var type_id  = $(this).data('agent-rule-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url      = ROOT_URL + '/admin/agent-rules/' + type_id + '/edit';
            $.get(url, function(data) {
                $('#dl-edit-agent-rule-modal .modal-body').html(data);
            });
        });
        $('a[disabled="disabled"]').on('click', function() { return false; });
    };

};

$(document).ready(function() {
    if ($('body#admin_agent_rules_index').length) {
        Application.view = new DLAdminAgentRulesView();
        Application.view.init();
    }
});
