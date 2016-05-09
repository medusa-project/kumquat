var PTAdminCollectionsView = function() {
    // Live-search text field
    $('.pt-live-search').submit(function () {
        $.get(this.action, $(this).serialize(), null, 'script');
        $(this).nextAll('input').addClass('active');
        return false;
    });
    var input_timer;
    $('.pt-live-search input').on('keyup', function() {
        var input = $(this);
        input.addClass('active');

        clearTimeout(input_timer);
        var msec = 800; // wait this long after user has stopped typing
        var forms = $('.pt-live-search');
        input_timer = setTimeout(function () {
            $.get(forms.attr('action'),
                forms.serialize(),
                function () { input.removeClass('active'); },
                'script');
            return false;
        }, msec);
        return false;
    });
};

var ready = function() {
    if ($('body#admin_collections_index').length) {
        PearTree.view = new PTAdminCollectionsView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
