/**
 * Handles list-collections view.
 *
 * @constructor
 */
var PTAdminCollectionsView = function() {

    var self = this;

    this.init = function() {
        new Application.FilterField();

        $('input[type=checkbox]').on('change', function() {
            $('form.pt-filter').submit();
        });

        self.attachEventListeners();
    };

    this.attachEventListeners = function() {
        $('.pagination a').on('click', function() {
            $('form.pt-filter')[0].scrollIntoView({behavior: "smooth"});
        });
    };

};

/**
 * Handles show-collection view.
 *
 * @constructor
 */
var PTAdminCollectionView = function() {

    this.init = function() {
        var ROOT_URL = $('input[name="root_url"]').val();
        var collection_id = $('input[name="pt-collection-id"]').val();

        $('button.pt-add-item-set').on('click', function() {
            var url = ROOT_URL + '/admin/collections/' + collection_id + '/item_sets/new';
            $.ajax({
                url: url,
                success: function (data) {
                    $('#pt-add-item-set-modal .modal-body').html(data);
                },
                error: function(a, b, c) {
                    console.error(a);
                    console.error(b);
                    console.error(c);
                }
            });
        });

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
    };

};

var PTAdminEditCollectionView = function() {

    this.init = function() {
        new PearTree.DirtyFormListener('form').listen();
    };

};

var ready = function() {
    if ($('body#admin_collections_index').length) {
        Application.view = new PTAdminCollectionsView();
        Application.view.init();
    } else if ($('body#admin_collections_show').length) {
        Application.view = new PTAdminCollectionView();
        Application.view.init();
    } else if ($('body#admin_edit_collection').length) {
        Application.view = new PTAdminEditCollectionView();
        Application.view.init();
    }
};

$(document).ready(ready);
