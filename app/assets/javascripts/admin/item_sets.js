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
        var collection_id = $('input[name="dl-collection-id"]').val();

        $('button.dl-edit-item-set').on('click', function() {
            var set_id = $(this).data('item-set-id');
            var url = ROOT_URL + '/admin/collections/' + collection_id +
                '/item_sets/' + set_id + '/edit';
            $.ajax({
                url: url,
                success: function (data) {
                    $('#dl-edit-item-set-modal .modal-body').html(data);
                },
                error: function(a, b, c) {
                    console.error(a);
                    console.error(b);
                    console.error(c);
                }
            });
        });

        $('.dl-remove-checked').on('click', function() {
            var href = $(this).attr('href') + '?';
            $('[name="dl-selected-items[]"]:checked').each(function() {
                href += 'items[]=' + $(this).val() + '&';
            });
            $(this).attr('href', href);
        });

        $('a.dl-check-all').on('click', function() {
            var checkboxes = $('#dl-items input[type=checkbox]');
            var checked = ($(this).data('checked') === 'true');

            if (checked) {
                checkboxes.prop('checked', false);
                $(this).data('checked', 'false');
                $(this).html('<i class="far fa-check-square"></i> Check All');
            } else {
                checkboxes.prop('checked', true);
                $(this).data('checked', 'true');
                $(this).html('<i class="far fa-minus-square"></i> Uncheck All');
            }
        });
    };

};

var ready = function() {
    if ($('body#admin_item_sets_show').length) {
        Application.view = new PTAdminItemSetView();
        Application.view.init();
    }
};

$(document).ready(ready);
