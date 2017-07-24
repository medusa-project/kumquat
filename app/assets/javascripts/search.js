var ready = function() {
    if ($('#search_index').length) {
        PearTree.view = new PTItemsView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
