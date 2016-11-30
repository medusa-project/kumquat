/**
 * @constructor
 */
var PTAdminAgentsView = function() {

    this.init = function() {
        $('button.pt-edit-agent').on('click', function() {
            var agent_id = $(this).data('agent-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url = ROOT_URL + '/admin/agents/' + agent_id + '/edit';
            $.get(url, function(data) {
                $('#pt-edit-agent-modal .modal-body').html(data);
            });
        });
        $('a[disabled="disabled"]').on('click', function() { return false; });
    };

};

var ready = function() {
    if ($('body#admin_agents_index').length) {
        PearTree.view = new PTAdminAgentsView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
