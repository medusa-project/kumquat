var ready = function() {
    if ($('#search_index').length) {
        new PTItemsView();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
