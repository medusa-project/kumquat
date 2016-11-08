var PTAdminCollectionsView = function() {

    var init = function() {
        new PearTree.FilterField();

        $('input[type=checkbox]').on('change', function() {
            $('form.pt-filter').submit();
        });
    }; init();

};

var ready = function() {
    if ($('body#admin_collections_index').length) {
        PearTree.view = new PTAdminCollectionsView();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
