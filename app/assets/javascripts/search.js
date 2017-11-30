var ready = function() {
    if ($('#search_index').length) {
        Application.view = new PTItemsView();
        Application.view.init();
    }
};

$(document).ready(ready);
