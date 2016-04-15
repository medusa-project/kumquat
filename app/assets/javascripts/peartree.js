var PearTree = {

    Events: {
        ITEM_ADDED_TO_FAVORITES: 'PTItemAddedToFavorites',
        ITEM_REMOVED_FROM_FAVORITES: 'PTItemRemovedFromFavorites'
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

            // make it disappear after a delay
            setTimeout(function() {
                flash.fadeOut();
            }, PearTree.Flash.FADE_OUT_DELAY);
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

    Util: {

        v4UUID: function() {
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
                var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
                return v.toString(16);
            });
        }

    },

    /**
     * Enables smooth scrolling to anchors.
     *
     * @param offset Integer
     */
    smoothAnchorScroll: function(offset) {
        $('a[href^="#"]').off('click').on('click', function(e) {
            // avoid interfering with other Bootstrap components
            if ($(this).data('toggle') == 'collapse' ||
                $(this).data('toggle') == 'tab') {
                return;
            }
            e.preventDefault();

            var target = this.hash;
            $('html, body').stop().animate(
                { 'scrollTop': $(target).offset().top - offset },
                500,
                'swing',
                function () {
                    window.location.hash = target;
                }
            );
        });
    },

    /**
     * Application-level initialization.
     */
    init: function() {
        // make flash messages disappear after a delay
        var flash = $('div.pt-flash');
        if (flash.length) {
            setTimeout(function () {
                flash.fadeOut();
            }, PearTree.Flash.FADE_OUT_DELAY);
        }

        // make the active nav bar nav active
        $('.navbar-nav li').removeClass('active');
        $('.navbar-nav li#' + $('body').attr('data-nav') + '-nav').addClass('active');

        // clear pt_* text from any search fields
        $('input[name="q"]').each(function() {
            if ($(this).val().match(/pt_/)) {
                $(this).val(null);
            }
        });

        var search_bar = new PearTree.SearchBar();
        $('#search-nav').on('click', function() {
            search_bar.toggle();
            return false;
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
