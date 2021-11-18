/**
 * Handles list-collections view.
 *
 * @constructor
 */
const DLAdminCollectionsView = function() {

    const self = this;

    this.init = function() {
        new Application.FilterField();

        self.attachEventListeners();
    };

    this.attachEventListeners = function() {
        $('input[type=checkbox]').on('change', function() {
            $('form.dl-filter').submit();
        });
        $('.pagination a').on('click', function() {
            $('form.dl-filter')[0].scrollIntoView({behavior: "smooth", block: "start"});
        });
    };

};

/**
 * Handles show-collection view.
 *
 * @constructor
 */
const DLAdminCollectionView = function() {

    const ROOT_URL = $('input[name="root_url"]').val();

    this.init = function() {
        const collection_id = $('input[name="dl-collection-id"]').val();

        $('button.dl-add-item-set').on('click', function() {
            var url = ROOT_URL + '/admin/collections/' + collection_id + '/item_sets/new';
            $.ajax({
                url: url,
                success: function (data) {
                    $('#dl-add-item-set-modal .modal-body').html(data);
                },
                error: function(a, b, c) {
                    console.error(a);
                    console.error(b);
                    console.error(c);
                }
            });
        });

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

        $('button.dl-edit-access').on('click', function() {
            const url = ROOT_URL + '/admin/collections/' + collection_id +
                '/edit-access';
            $.get(url, function(data) {
                $('#dl-edit-access-modal .modal-body').html(data);
                attachEventListeners();
            });
        });
        $('button.dl-edit-email-watchers').on('click', function() {
            const url = ROOT_URL + '/admin/collections/' + collection_id +
                '/edit-email-watchers';
            $.get(url, function(data) {
                $('#dl-edit-email-watchers-modal .modal-body').html(data);
                attachEventListeners();
            });
        });
        $('button.dl-edit-info').on('click', function() {
            const url = ROOT_URL + '/admin/collections/' + collection_id +
                '/edit-info';
            $.get(url, function(data) {
                $('#dl-edit-info-modal .modal-body').html(data);
                attachEventListeners();
            });
        });
        $('button.dl-edit-representation').on('click', function() {
            const url = ROOT_URL + '/admin/collections/' + collection_id +
                '/edit-representation';
            $.get(url, function(data) {
                $('#dl-edit-representation-modal .modal-body').html(data);
                attachEventListeners();
            });
        });

        const attachEventListeners = function() {
            $('button.dl-remove').on('click', function() {
                const row = $(this).closest('.input-group');
                const siblings = row.siblings('.input-group');
                if (siblings.length > 0) {
                    row.remove();
                } else {
                    row.find('input').val('');
                }
                return false;
            });
            $('button.dl-add').on('click', function() {
                const lastRow = $(this).closest('form').find('.input-group:last');
                const clone = lastRow.clone(true);
                clone.find('input[type=text]').val('');
                lastRow.after(clone);
                return false;
            });
        }
    };

};

const DLAdminEditCollectionView = function() {

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

$(document).ready(function() {
    if ($('body#admin_collections_index').length) {
        Application.view = new DLAdminCollectionsView();
        Application.view.init();
    } else if ($('body#admin_collections_show').length) {
        Application.view = new DLAdminCollectionView();
        Application.view.init();
    } else if ($('body#admin_edit_collection').length) {
        Application.view = new DLAdminEditCollectionView();
        Application.view.init();
    }
});
