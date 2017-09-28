/**
 * Handles show-item-set view.
 *
 * @constructor
 */
var PTAdminItemSetView = function() {

    this.init = function() {
        attachEventListeners();
    };

    var attachEventListeners = function() {
        var ROOT_URL = $('input[name="root_url"]').val();
        var collection_id = $('input[name="pt-collection-id"]').val();

        $('button.pt-edit-item-set').on('click', function() {
            var set_id = $(this).data('item-set-id');
            var url = ROOT_URL + '/admin/collections/' + collection_id +
                '/item_sets/' + set_id + '/edit';
            $.ajax({
                url: url,
                success: function (data) {
                    $('#pt-edit-item-set-modal .modal-body').html(data);
                },
                error: function(a, b, c) {
                    console.error(a);
                    console.error(b);
                    console.error(c);
                }
            });
        });

        $('.pt-remove-checked').on('click', function() {
            var href = $(this).attr('href') + '?';
            $('[name="pt-selected-items[]"]:checked').each(function() {
                href += 'items[]=' + $(this).val() + '&';
            });
            $(this).attr('href', href);
        });

        $('a.pt-check-all').on('click', function() {
            var checkboxes = $('#pt-items input[type=checkbox]');
            var checked = ($(this).data('checked') === 'true');

            if (checked) {
                checkboxes.prop('checked', false);
                $(this).data('checked', 'false');
                $(this).html('<i class="fa fa-check-square-o"></i> Check All');
            } else {
                checkboxes.prop('checked', true);
                $(this).data('checked', 'true');
                $(this).html('<i class="fa fa-minus-square-o"></i> Uncheck All');
            }
        });
    };

};

var ready = function() {
    if ($('body#admin_item_sets_show').length) {
        PearTree.view = new PTAdminItemSetView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
