var PearTree = {

    Events: {
        ITEM_ADDED_TO_FAVORITES: 'PTItemAddedToFavorites',
        ITEM_REMOVED_FROM_FAVORITES: 'PTItemRemovedFromFavorites'
    },

    /**
     * Enables the facets returned by one of the facets_as_x() helpers.
     *
     * @constructor
     */
    initFacets: function() {
        var addFacetEventListeners = function() {
            $('[name="pt-facet-term"]').on('change', function() {
                // Create hidden input counterparts of each checked checkbox, as
                // checkboxes' values can't change.
                var form = $(this).parents('form:first');
                form.find('[name="fq[]"]').remove();
                form.find('[name=pt-facet-term]:checked').each(function() {
                    var input = $('<input type="hidden" name="fq[]">');
                    input.val($(this).data('query'));
                    form.append(input);
                });

                $.ajax({
                    url: $('[name=pt-current-path]').val(),
                    method: 'GET',
                    data: form.serialize(),
                    dataType: 'script',
                    success: function(result) {
                        eval(result);
                    }
                });
            });
        };

        // When a filter field has been updated, it will change the facets.
        $(document).ajaxSuccess(function(event, request) {
            addFacetEventListeners();
        });
        addFacetEventListeners();
    },

    /**
     * Provides an ajax filter field. This will contain HTML like:
     *
     * <form class="pt-filter">
     *     <input type="text">
     *     <select> <!-- optional -->
     * </form>
     *
     * @constructor
     */
    FilterField: function() {
        var INPUT_DELAY_MSEC = 500;

        $('form.pt-filter').submit(function () {
            $.get(this.action, $(this).serialize(), null, 'script');
            $(this).nextAll('input').addClass('active');
            return false;
        });

        var submitForm = function () {
            var forms = $('form.pt-filter');
            $.ajax({
                url: forms.attr('action'),
                method: 'GET',
                data: forms.serialize(),
                dataType: 'script',
                success: function(result) {}
            });
            return false;
        };

        var input_timer;
        // When text is typed in the filter field...
        $('form.pt-filter input').on('keyup', function () {
            // Reset the typing-delay counter.
            clearTimeout(input_timer);

            // After the user has stopped typing, wait a bit and then submit
            // the form via AJAX.
            input_timer = setTimeout(submitForm, INPUT_DELAY_MSEC);
            return false;
        });
        // When a select menu accompanying the filter field is changed,
        // resubmit the form via AJAX.
        $('form.pt-filter select').on('change', function() {
            submitForm();
        });
    },

    Flash: {

        FADE_OUT_DELAY: 10000,

        /**
         * @param text
         * @param type Value of the X-PearTree-Message-Type header
         * @return void
         */
        set: function(text, type) {
            var bootstrap_class;
            switch (type) {
                case 'success':
                    bootstrap_class = 'alert-success';
                    break;
                case 'error':
                    bootstrap_class = 'alert-danger';
                    break;
                case 'alert':
                    bootstrap_class = 'alert-block';
                    break;
                default:
                    bootstrap_class = 'alert-info';
                    break;
            }

            // remove any existing messages
            $('div.pt-flash').remove();

            // construct the message
            var flash = $('<div class="pt-flash alert ' + bootstrap_class + '"></div>');
            var button = $('<button type="button" class="close"' +
            ' data-dismiss="alert" aria-hidden="true">&times;</button>');
            flash.append(button);
            button.after(text);

            // append the flash to the DOM
            $('#pt-page-content').before(flash);
        }

    },

    loadLazyImages: function() {
        $('img[data-src]').each(function(index, img) {
            img = $(img);
            img.attr('src', img.data('src'));
        });
    },

    /**
     * Enables smooth scrolling to anchors. This is called by PearTree.init()
     * to take effect globally, but is safe to call again to use a different
     * offset.
     *
     * @param offset [Integer]
     */
    smoothAnchorScroll: function(offset) {
        if (!offset && offset !== 0) {
            offset = 0;
        }
        var top_padding = $('nav.navbar.navbar-default').height() + 10 + offset;
        var root = $('html, body');

        $('a[href^="#"]').off('click').on('click', function(e) {
            // avoid interfering with other Bootstrap components
            if ($(this).data('toggle') === 'collapse' ||
                $(this).data('toggle') === 'tab') {
                return;
            }
            e.preventDefault();

            var target = this.hash;
            root.stop().animate({
                'scrollTop': $(target).offset().top - top_padding
            }, 500, 'swing', function () {
                window.location.hash = target;
            });
        });
    },

    /**
     * Application-level initialization.
     */
    init: function() {
        // make the active nav bar nav active
        $('.navbar-nav li').removeClass('active');
        $('.navbar-nav li#' + $('body').attr('data-nav') + '-nav')
            .addClass('active');

        // Add an expander icon in front of every collapse toggle.
        var toggleForCollapse = function(collapse) {
            return collapse.prev().find('a[data-toggle="collapse"]:first');
        };
        var setToggleState = function(elem, expanded) {
            var class_ = expanded ? 'fa-minus-square-o' : 'fa-plus-square-o';
            elem.html('<i class="fa ' + class_ + '"></i> ' + elem.text());
        };

        var collapses = $('.collapse');
        collapses.each(function() {
            setToggleState(toggleForCollapse($(this)), $(this).hasClass('in'));
        });
        collapses.on('show.bs.collapse', function () {
            setToggleState(toggleForCollapse($(this)), true);
        });
        collapses.on('hide.bs.collapse', function () {
            setToggleState(toggleForCollapse($(this)), false);
        });

        PearTree.smoothAnchorScroll(0);
    },

    /**
     * @return An object representing the current view.
     */
    view: null

};

var ready = function() {
    PearTree.init();
};

$(document).ready(ready);
$(document).on('page:load', ready);
