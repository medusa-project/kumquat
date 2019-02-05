/**
 * Handles list-collections view.
 *
 * @constructor
 */
var PTAdminCollectionsView = function() {

    var self = this;

    this.init = function() {
        new Application.FilterField();

        self.attachEventListeners();
    };

    this.attachEventListeners = function() {
        $('input[type=checkbox]').on('change', function() {
            $('form.pt-filter').submit();
        });
        $('.pagination a').on('click', function() {
            $('form.pt-filter')[0].scrollIntoView({behavior: "smooth", block: "start"});
        });
    };

};

/**
 * Handles show-collection view.
 *
 * @constructor
 */
var PTAdminCollectionView = function() {

    var ROOT_URL = $('input[name="root_url"]').val();

    this.init = function() {
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

    var ROOT_URL = $('input[name="root_url"]').val();

    this.init = function() {
        new Application.DirtyFormListener('form').listen();

        // When the metadata profile is changed, reload the descriptive
        // elements menu.
        $('#collection_metadata_profile_id').on('change', function() {
            var menu = $('#collection_descriptive_element_id');
            menu.empty();

            $.ajax({
                url: ROOT_URL + '/admin/metadata-profiles/' + $(this).val() + '.json',
                success: function (data) {
                    data.elements.forEach(function(e) {
                        var selected = (e.id === parseInt($('[name=current_descriptive_element_id]').val()));
                        menu.append('<option value="' + e.id + '" ' +
                            (selected ? 'selected' : '') + '>' + e.label + '</option>');
                    });
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
