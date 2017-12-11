/**
 * @constructor
 */
var PTAdminAgentRulesView = function() {

    this.init = function() {
        $('button.pt-edit-agent-rule').on('click', function() {
            var type_id = $(this).data('agent-rule-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url = ROOT_URL + '/admin/agent-rules/' + type_id + '/edit';
            $.get(url, function(data) {
                $('#pt-edit-agent-rule-modal .modal-body').html(data);
            });
        });
        $('a[disabled="disabled"]').on('click', function() { return false; });
    };

};

var ready = function() {
    if ($('body#admin_agent_rules_index').length) {
        Application.view = new PTAdminAgentRulesView();
        Application.view.init();
    }
};

$(document).ready(ready);
