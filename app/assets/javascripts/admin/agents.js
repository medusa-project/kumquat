var PTAdminAgentEditForm = function() {

    this.init = function() {
        var updateRowIndices = function(table) {
            table.find('tr').each(function(index, element) {
                $(element).find('input').each(function() {
                    var input = $(this);
                    var newId = input.attr('id')
                        .replace(/_[0-9]_/, '_' + index + '_');
                    var newName = input.attr('name')
                        .replace(/\[[0-9]]/, '[' + index + ']');
                    input.attr('id', newId);
                    input.attr('name', newName);
                });
            });
        };
        $('button.pt-add').on('click', function() {
            var lastRow = $(this).prev('table').find('tr:last');
            var clone = lastRow.clone(true);
            clone.find('input[type=text]').val('');
            clone.find('input[type=radio]').prop('checked', false);
            lastRow.after(clone);
            updateRowIndices($(this).prev('table'));
            return false;
        });
        $('button.pt-remove').on('click', function() {
            var form = $(this).closest('form');
            var row = $(this).closest('tr');
            var siblings = row.siblings();
            if (siblings.length > 0) {
                row.remove();
                if (siblings.find('input[type=radio]:checked').length < 1) {
                    siblings.filter(':first').find('input[type=radio]')
                        .prop('checked', true);
                }
            }
            updateRowIndices(row.closest('table'));
            return false;
        });
        // When a radio is checked, uncheck all the others. The radios all have
        // different names, so this won't happen automatically.
        $('input[type=radio]').on('click', function() {
            var clickedRadio = $(this);
            $('table#pt-agent-uris').find('input[type=radio]').each(function() {
                if ($(this).attr('name') != clickedRadio.attr('name')) {
                    $(this).prop('checked', false);
                }
            });
        });
    };

};

var PTAdminAgentRelationForm = function() {

    this.init = function() {
        $('input.pt-autocomplete').on('keyup', function() {
            $(this).parents('.form-group').find('.pt-suggestions').remove();

            var input = $(this);
            var agents_url = $('[name=root_url]').val() +
                '/admin/agents.json?q=' + input.val();

            $.getJSON(agents_url, function(data) {
                var suggestionsDiv = '<div class="pt-suggestions"><ul>';
                data.forEach(function(agent) {
                    suggestionsDiv += '<li>' + agent['name'] + '</li>'
                });
                suggestionsDiv += '</ul></div>';
                input.parent().append(suggestionsDiv);

                $('.pt-suggestions li').on('click', function() {
                    input.val($(this).text());
                    $(this).parent().remove();
                    return false;
                });
            });
        });
    };

};

/**
 * Handles list-agents view.
 *
 * @constructor
 */
var PTAdminAgentsView = function() {

    this.init = function() {
        new PearTree.FilterField();
        $('form.pt-filter input').on('change', function() {
            $('form.pt-filter').submit();
        });

        $('button.pt-edit-agent').on('click', function() {
            var agent_id = $(this).data('agent-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url = ROOT_URL + '/admin/agents/' + agent_id + '/edit';
            $.get(url, function(data) {
                $('#pt-edit-agent-modal .modal-body').html(data);
            });
        });
        $('a[disabled="disabled"]').on('click', function() { return false; });

        new PTAdminAgentEditForm().init();
    };

};

/**
 * Handles show-agent view.
 *
 * @constructor
 */
var PTAdminAgentView = function() {

    this.init = function() {
        $('button.pt-edit-agent-relation').on('click', function() {
            var agent_relation_id = $(this).data('agent-relation-id');
            var ROOT_URL = $('input[name="root_url"]').val();
            var url = ROOT_URL + '/admin/agent-relations/' + agent_relation_id + '/edit';
            $.get(url, function(data) {
                $('#pt-agent-relation-modal .modal-body').html(data);
                new PTAdminAgentRelationForm().init();
            });
        });

        new PTAdminAgentEditForm().init();
        new PTAdminAgentRelationForm().init();
    };

};

var ready = function() {
    if ($('body#admin_agents_index').length) {
        PearTree.view = new PTAdminAgentsView();
        PearTree.view.init();
    } else if ($('body#admin_agents_show').length) {
        PearTree.view = new PTAdminAgentView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
