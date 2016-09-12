var PTAdminCollectionsView = function() {

    var init = function() {
        $('form.pt-filter').submit(function () {
            $.get(this.action, $(this).serialize(), null, 'script');
            $(this).nextAll('input').addClass('active');
            return false;
        });

        var input_timer;
        $('form.pt-filter input').on('keyup', function () {
            var input = $(this);
            input.addClass('active');

            clearTimeout(input_timer);
            var msec = 600; // wait this long after user has stopped typing
            var forms = $('form.pt-filter');
            input_timer = setTimeout(function () {
                $.get(forms.attr('action'),
                    forms.serialize(),
                    function () {
                        input.removeClass('active');
                    },
                    'script');
                return false;
            }, msec);
            return false;
        });

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
