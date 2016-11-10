var ready = function() {
    if ($('#search_index').length) {
        new PTItemsView().init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
