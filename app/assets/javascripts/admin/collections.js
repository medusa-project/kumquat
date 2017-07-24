var PTAdminCollectionsView = function() {

    var self = this;

    this.init = function() {
        new PearTree.FilterField();

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

var ready = function() {
    if ($('body#admin_collections_index').length) {
        PearTree.view = new PTAdminCollectionsView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
