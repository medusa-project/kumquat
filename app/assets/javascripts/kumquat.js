var Application = {

    /**
     * Enables the facets returned by one of the facets_as_x() helpers.
     */
    initFacets: function() {
        var addFacetEventListeners = function() {
            $('[name="dl-facet-term"]').on('change', function() {
                // Create hidden input counterparts of each checked checkbox, as
                // checkboxes' values can't change.
                var form = $(this).parents('form:first');
                form.find('[name="fq"]').remove();
                form.find('[name="fq[]"]').remove();
                form.find('[name=dl-facet-term]:checked').each(function() {
                    var input = $('<input type="hidden" name="fq[]">');
                    input.val($(this).data('query'));
                    form.append(input);
                });

                $.ajax({
                    url: $('[name=dl-current-path]').val(),
                    method: 'GET',
                    data: form.serialize(),
                    dataType: 'script',
                    success: function(result) {
                        eval(result);
                    },
                    error: function(xhr, status, error) {
                        console.error(xhr.responseText);
                        console.error(status);
                        console.error(error);
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

    initThumbnails: function() {
        $('.dl-thumbnail-container img[data-location="remote"]').one('load', function() {
            $(this).parent().next('.dl-load-indicator').hide();
            $(this).animate({'opacity': 1}, 300);
        }).on('error', function() {
            $(this).parent().next('.dl-load-indicator').hide();
        }).each(function() {
            if (this.complete) {
                $(this).trigger('load');
            }
        });
    },

    /**
     * Encapsulates an AJAX shade with a spinner. Use the ajax_shade() helper
     * to add the shade div to the layout, instantiate an AJAXShade, and call
     * show() or hide() on it.
     *
     * @constructor
     */
    AJAXShade: function() {

        var shade = $('#dl-ajax-shade');
        // http://spin.js.org
        var spinner = new Spinner({
            lines: 13 // The number of lines to draw
            , length: 28 // The length of each line
            , width: 14 // The line thickness
            , radius: 42 // The radius of the inner circle
            , scale: 1 // Scales overall size of the spinner
            , corners: 1 // Corner roundness (0..1)
            , color: '#fff' // #rgb or #rrggbb or array of colors
            , opacity: 0.25 // Opacity of the lines
            , rotate: 0 // The rotation offset
            , direction: 1 // 1: clockwise, -1: counterclockwise
            , speed: 1 // Rounds per second
            , trail: 60 // Afterglow percentage
            , fps: 20 // Frames per second when using setTimeout() as a fallback for CSS
            , zIndex: 2e9 // The z-index (defaults to 2000000000)
            , className: 'spinner' // The CSS class to assign to the spinner
            , top: '50%' // Top position relative to parent
            , left: '50%' // Left position relative to parent
            , shadow: false // Whether to render a shadow
            , hwaccel: false // Whether to use hardware acceleration
            , position: 'absolute' // Element positioning
        });

        this.hide = function() {
            spinner.stop();
            shade.hide();
        };

        this.show = function() {
            spinner.spin(shade[0]);
            shade.show();
        };

    },

    /**
     * Marks changed form fields as dirty.
     *
     * @param form_selector jQuery form selector
     * @constructor
     */
    DirtyFormListener: function(form_selector) {

        var DIRTY_CLASS = 'dl-dirty';

        this.listen = function() {
            // When the value of a text input changes, mark it as dirty.
            // (DLD-197)
            var inputs = $(form_selector)
                .find('input[type=text], input[type=number], select, textarea');
            inputs.each(function () {
                $(this).removeClass(DIRTY_CLASS);
                $(this).data('initial-value', $(this).val());
            });
            inputs.on('propertychange keyup change', function () {
                var initial_value = $(this).data('initial-value');
                if (initial_value === undefined) {
                    initial_value = '';
                }
                if ((initial_value && $(this).val() === initial_value) ||
                    (!initial_value && !$(this).val())) {
                    $(this).removeClass(DIRTY_CLASS);
                } else {
                    $(this).addClass(DIRTY_CLASS);
                }
            });
        }

    },

    /**
     * Provides an ajax filter field. This will contain HTML like:
     *
     * <form class="dl-filter">
     *     <input type="text">
     *     <select> <!-- optional -->
     * </form>
     *
     * @constructor
     */
    FilterField: function() {
        var INPUT_DELAY_MSEC = 500;

        $('form.dl-filter').submit(function () {
            $.get(this.action, $(this).serialize(), null, 'script');
            $(this).nextAll('input').addClass('active');
            return false;
        });

        var submitForm = function () {
            var forms = $('form.dl-filter');
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
        $('form.dl-filter input').on('keyup', function () {
            // Reset the typing-delay counter.
            clearTimeout(input_timer);

            // After the user has stopped typing, wait a bit and then submit
            // the form via AJAX.
            input_timer = setTimeout(submitForm, INPUT_DELAY_MSEC);
            return false;
        });
        // When form controls accompanying the filter field are changed,
        // resubmit the form via AJAX.
        $('form.dl-filter select, form.dl-filter input[type=radio]').on('change', function() {
            submitForm();
        });
    },

    Flash: {

        FADE_OUT_DELAY: 10000,

        /**
         * @param text
         * @param type Value of the X-Kumquat-Message-Type header
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
            $('div.dl-flash').remove();

            // construct the message
            var flash = $('<div class="dl-flash alert ' + bootstrap_class + '"></div>');
            var button = $('<button type="button" class="close"' +
            ' data-dismiss="alert" aria-hidden="true">&times;</button>');
            flash.append(button);
            button.after(text);

            // append the flash to the DOM
            $('.page-content').before(flash);
        }

    },

    loadLazyImages: function() {
        $('img[data-src]').each(function(index, img) {
            img = $(img);
            img.attr('src', img.data('src'));
        });
    },

    /**
     * Enables smooth scrolling to anchors. This is called by Application.init()
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
            if (target) {
                root.stop().animate({
                    'scrollTop': $(target).offset().top - top_padding
                }, 500, 'swing', function () {
                    window.location.hash = target;
                });
            }
        });
    },

    /**
     * Application-level initialization.
     */
    init: function() {
        // Disable disabled anchors.
        $('a[disabled="disabled"]').click(function(e){
            e.preventDefault();
            return false;
        });

        // make the active nav bar nav active
        $('nav .container-fluid:last-child .navbar-nav li').removeClass('active');
        $('.navbar-nav li#' + $('body').attr('data-nav') + '-nav')
            .addClass('active');

        // Add an expander icon in front of every collapse toggle.
        var toggleForCollapse = function(collapse) {
            return collapse.prev().find('a[data-toggle="collapse"]:first');
        };
        var setToggleState = function(elem, expanded) {
            var class_ = expanded ? 'fa-minus-square' : 'fa-plus-square';
            elem.html('<i class="far ' + class_ + '"></i> ' + elem.text());
        };

        var collapses = $('.collapse');
        collapses.each(function() {
            if (!$(this).hasClass('dl-supplmentary-viewer-content')) {
                setToggleState(toggleForCollapse($(this)), $(this).hasClass('show'));
            }
        });
        collapses.on('show.bs.collapse', function () {
            if (!$(this).hasClass('dl-supplmentary-viewer-content')) {
                setToggleState(toggleForCollapse($(this)), true);
            }
        });
        collapses.on('hide.bs.collapse', function () {
            if (!$(this).hasClass('dl-supplmentary-viewer-content')) {
                setToggleState(toggleForCollapse($(this)), false);
            }
        });

        Application.smoothAnchorScroll(0);

        // These global AJAX success and error callbacks save the work of
        // defining local ones in many $.ajax() calls.
        //
        // This one sets the flash if there are `X-Kumquat-Message` and
        // `X-Kumquat-Message-Type` response headers. These would be set by
        // an ApplicationController after_filter. `X-Kumquat-Result` is
        // another header that, if set, can contain "success" or "error",
        // indicating the result of a form submission.
        $(document).ajaxSuccess(function(event, request) {
            var result_type = request.getResponseHeader('X-Kumquat-Message-Type');
            var edit_panel = $('.dl-edit-panel.in');

            if (result_type && edit_panel.length) {
                if (result_type === 'success') {
                    edit_panel.modal('hide');
                } else if (result_type === 'error') {
                    edit_panel.find('.modal-body').animate({ scrollTop: 0 }, 'fast');
                }
                var message = request.getResponseHeader('X-Kumquat-Message');
                if (message && result_type) {
                    Application.Flash.set(message, result_type);
                }
            }
        });

        $(document).ajaxError(function(event, request, settings) {
            console.error(event);
            console.error(request);
            console.error(settings);
        });
    },

    /**
     * @return An object representing the current view.
     */
    view: null

};

var ready = function() {
    Application.init();
};

$(document).ready(ready);
