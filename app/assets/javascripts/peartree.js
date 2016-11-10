var PearTree = {

    Events: {
        ITEM_ADDED_TO_FAVORITES: 'PTItemAddedToFavorites',
        ITEM_REMOVED_FROM_FAVORITES: 'PTItemRemovedFromFavorites'
    },

    /**
     * Provides an ajax filter field.
     *
     * @constructor
     */
    FilterField: function() {
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
            var msec = 500; // wait this long after user has stopped typing
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

    SearchBar: function() {

        var ELEMENT = $('#pt-search-accordion');
        if (!ELEMENT.length) {
            return false;
        }
        var SPEED = 200;
        var computed_height = ELEMENT.height();
        var vertical_padding = parseFloat(ELEMENT.css('padding-top').replace(/px/, '')) +
            parseFloat(ELEMENT.css('padding-bottom').replace(/px/, ''));
        var visible = false;
        var self = this;

        /** constructor */
        (function(){
            ELEMENT.css('margin-top',
                '-' + $('#pt-main-nav').css('margin-bottom'));
            ELEMENT.css('height', 0);

            ELEMENT.find('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
                ELEMENT.animate({ 'height': ELEMENT.find('div').height() + 50 });
            });
        })();

        this.hide = function() {
            ELEMENT.animate({ 'height': '0px' }, SPEED);
            visible = false;
        };

        this.show = function() {
            ELEMENT.animate({ 'height': '+=' + (computed_height + vertical_padding) + 'px' }, SPEED);
            visible = true;
        };

        this.toggle = function() {
            visible ? self.hide() : self.show();
        };

    },

    /**
     * Application-level initialization.
     */
    init: function() {
        // make the active nav bar nav active
        $('.navbar-nav li').removeClass('active');
        $('.navbar-nav li#' + $('body').attr('data-nav') + '-nav').addClass('active');

        // clear pt_* text from any search fields
        $('input[name="q"]').each(function() {
            if ($(this).val().match(/pt_/)) {
                $(this).val(null);
            }
        });
        // Add an expander icon in front of every collapse toggle.
        var toggleForCollapse = function(collapse) {
            return collapse.prev().find('a[data-toggle="collapse"]:first');
        };
        var setToggleState = function(elem, expanded) {
            var class_ = expanded ? 'fa-minus-square-o' : 'fa-plus-square-o';
            elem.html('<i class="fa ' + class_ + '"></i> ' + elem.text());
        };

        var search_bar = new PearTree.SearchBar();
        $('#search-nav').on('click', function() {
            search_bar.toggle();
            return false;
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
