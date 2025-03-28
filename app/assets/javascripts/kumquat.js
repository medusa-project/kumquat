const Application = {

    SCROLL_SPEED: 500,

    /**
     * Enables the facets returned by one of the facets_as_x() helpers.
     */
    initFacets: function() {
        const CURRENT_PATH = $('[name=dl-current-path]').val();
        const filterForm = $("form.dl-filter");

        const getSerializedCanonicalFormQuery = function() {
            return filterForm.find(':not([name=collection_id], [name=dl-facet-term])')
                .serialize();
        };

        const removeHiddenInputs = function () {
            filterForm.find('[name="fq"], [name="fq[]"]').remove();
        };
        const createHiddenInputs = function() {
            removeHiddenInputs();
            // Create hidden input counterparts of each checked checkbox.
            filterForm.find('[name=dl-facet-term]:checked').each(function() {
                const input = $('<input type="hidden" name="fq[]">');
                input.val($(this).data('query'));
                filterForm.append(input);
            });
        };

        filterForm.find('.dl-card-facet [name="dl-facet-term"]').off().on('change', function() {
            $(this).prop("checked") ?
                createHiddenInputs() : removeHiddenInputs();
            const query = getSerializedCanonicalFormQuery();
            $.ajax({
                url:      CURRENT_PATH,
                method:   'GET',
                data:     query,
                dataType: 'script',
                success:  function(result) {
                    window.location.hash = query;
                    eval(result);
                }
            });
        });
        filterForm.find('.dl-modal-facet .modal-footer button.submit').off().on('click', function(e) {
            e.preventDefault();
            const modal = $(this).parents(".dl-modal-facet");
            modal.on("hidden.bs.modal", function() {
                createHiddenInputs();
                const query = getSerializedCanonicalFormQuery();
                $.ajax({
                    url:      CURRENT_PATH,
                    method:   'GET',
                    data:     query,
                    dataType: 'script',
                    success: function(result) {
                        window.location.hash = query;
                        eval(result);
                    }
                });
            });
            modal.modal("hide");
        });


    },

    initThumbnails: function() {
        var containers = $('.dl-thumbnail-container');
        containers.find('img[data-location="local"]').parent()
            .next('.dl-load-indicator').hide();
        containers.find('img[data-location="remote"]').one('load', function() {
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
     * @returns {Boolean}
     */
    isPDFSupportedNatively: function() {
        function hasAcrobatInstalled() {
            function getActiveXObject(name) {
                try { return new ActiveXObject(name); } catch(e) {}
            }
            return getActiveXObject('AcroPDF.PDF') || getActiveXObject('PDF.PdfCtrl');
        }

        function isApple() {
            return /Mac|iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream
        }

        return navigator.mimeTypes['application/pdf'] || hasAcrobatInstalled() || isApple();
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
        var progressBar = $('<div class="progress-bar progress-bar-striped progress-bar-animated bg-info" role="progressbar" style="width: 100%; height: 2em;"></div>');
        var progressContainer = $('<div class="progress" style="height: 2em;"></div>').append(progressBar);

        this.hide = function() {
            progressContainer.hide();
            shade.hide();
        };

        this.show = function() {
            shade.append(progressContainer);
            progressContainer.show();
            shade.show();
        };

    },

    CaptchaProtectedDownload: function() {
        const modal = $("#dl-download-zip-modal");
        const modalBody = modal.find(".modal-body");
        const originalModalContent = modalBody.html();
        function handleFormSubmit(e) {
          e.preventDefault();
          const form = $(e.target);
          form.find(".alert").remove();

          let url = form.attr("action").includes("?")
            ? form.attr('action') + "&" + form.serialize()
            : form.attr('action') + "?" + form.serialize();

          $.ajax({
            url: url,
            method: 'GET',
            dataType: 'script',
            success: function (data, status, xhr) {
              const waitMessageHTML = `
                <p>Your file is being prepared. When it's ready, a download button will appear below.</p>
                <div class="text-center">
                  <div class="progress-bar progress-bar-striped progres-bar-animated bg-info"
                    role="progressbar" style="width: 100%; height: 2em;">
                </div>
              </div>
            `;

            modalBody.html(waitMessageHTML);

            const pollingUrl = xhr.getResponseHeader("X-Kumquat-Location");
            if (!pollingUrl) {
              modalBody.append("<p class='text-danger'>Error: No polling URL found.</p>");
              return;
            }

            startPolling(pollingUrl);
      },
      error: function(request, status, error) {
        const message = request.getResponseHeader('X-Kumquat-Message') || "An error occurred.";
        form.prepend(`<div class='alert alert-danger'>${message}</div`);
        }
      });
    }

    function startPolling(pollingUrl) {
      const intervalID = setInterval(function () {
        $.ajax({
          url: pollingUrl,
          method: 'GET',
          dataType: 'json',
          success: function (data, status, xhr) {
            let href = data.filename ? `/downloads/${data.key}/file` : data.url;
            let pct = data.task.total > 0 ? Math.round(100 * data.task.current / data.task.total) : 0;

            if (parseInt(data.task.status) === 4) {
              modalBody.html("<p>There was an error preparing the file.</p>");
              clearInterval(intervalID);
            } else if (href) {
              modalBody.html(`
                <p class="text-center">Your download is ready!</p>
                <div class="text-center mt-3">
                  <a href="${href}" class="btn btn-success btn-lg d-flex align-items-center justify-content-center" download>
                    <i class="fas fa-download me-2"></i>Download File
                  </a>
                </div>
              `);
              clearInterval(intervalID);
            } else {
              modalBody.html(`
                <p>Your file is being prepared. Please wait...</p>
                <div class="progress">
                  <div class="progress-bar progress-bar-striped progress-bar-animated bg-info"
                    role="progressbar" style="width: ${pct}%;">
                  </div>
                </div>
                <p class="text-center">${pct}%</p>`
                  
              );
            }
          },
          error: function() {
            clearInterval(intervalID);
            modalBody.append("<p class='alert alert-danger'>Failed to retrieve download status.</p>");
          }
        });
      }, 5000);
    }

    function resetModal() {
      modalBody.html(originalModalContent);
      modal.find(".dl-captcha-form").off("submit", handleFormSubmit).on("submit", handleFormSubmit);
    }

    modal.find(".dl-captcha-form").on("submit", handleFormSubmit);

    modal.on('hidden.bs.modal', resetModal);
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
        const INPUT_DELAY_MSEC = 500;
        const form = $('form.dl-filter');

        form.submit(function () {
            $.get(this.action, $(this).serialize(), null, 'script');
            $(this).nextAll('input').addClass('active');
            return false;
        });

        const submitForm = function () {
            const query = form.serialize();
            $.ajax({
                url: form.attr('action'),
                method: 'GET',
                data: query,
                dataType: 'script',
                success: function(result) {
                    // Enables results page persistence after back/forward
                    // navigation.
                    window.location.hash = query;
                }
            });
            return false;
        };

        var input_timer;
        // When text is typed in the filter field...
        form.find('input[name=q]').on('keyup', function () {
            // Reset the typing-delay counter.
            clearTimeout(input_timer);
            // After the user has stopped typing, wait a bit and then submit
            // the form via AJAX.
            input_timer = setTimeout(submitForm, INPUT_DELAY_MSEC);
            return false;
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
                }, Application.SCROLL_SPEED, 'swing', function () {
                    window.location.hash = target;
                });
            }
        });
    },

    /**
     * Application-level initialization.
     */
    init: function() {
        // Don't allow disabled elements to be clicked.
        $("[disabled='disabled']").on("click", function() {
            return false;
        });

        // make the active nav bar nav active
        $('nav .container-fluid:last-child .navbar-nav li').removeClass('active');
        $('.navbar-nav li#' + $('body').attr('data-nav') + '-nav')
            .addClass('active');

        // Add an expander icon in front of every collapse toggle.
        const toggleForCollapse = function(collapse) {
            return collapse.prev().find('a[data-bs-toggle="collapse"]:first');
        };
        const setToggleState = function(elem, expanded) {
            var class_ = expanded ? 'fa-minus-square' : 'fa-plus-square';
            elem.html('<i class="far ' + class_ + '"></i> ' + elem.text());
        };

        const collapses = $('.collapse');
        collapses.each(function() {
            setToggleState(toggleForCollapse($(this)), $(this).hasClass('show'));
        });
        collapses.on('show.bs.collapse', function () {
            setToggleState(toggleForCollapse($(this)), true);
        });
        collapses.on('hide.bs.collapse', function () {
            setToggleState(toggleForCollapse($(this)), false);
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
        $(document).on('submit', '#contact-form', function(event) { 
          // event.preventDefault();
          console.log('Form submit event triggered');
          
          var $form = $(this);
          console.log('Form action:', $form.attr('action'));
        });

      //     $.ajax({
      //       type: $form.attr('method'),
      //       url: $form.attr('action'),
      //       data: $form.serialize(),
      //       success: function(response, status, xhr) {
      //         console.log('AJAX request successful');
      //         var result_type = xhr.getResponseHeader('X-Kumquat-Message-Type');
      //         var message = xhr.getResponseHeader('X-Kumquat-Message');
      //         console.log('Result Type:', result_type);
      //         console.log('Message:', message);
      //         if (result_type && message) {
      //           Application.Flash.set(message, result_type);
      //         }
      //         if (result_type === 'success') {
      //           $form.closest('.collapse').collapse('hide');
      //         }
      //       }, 
      //       error: function(xhr) {
      //         console.log('AJAX request failed');
      //         var result_type = xhr.getResponseHeader('X-Kumquat-Message-Type');
      //         var message = xhr.responseText;
      //         // var message = xhr.getResponseHeader('X-Kumquat-Message');
      //         console.log('Error Result Type:', result_type);
      //         console.log('Error Message:', message);
      //         if (message) {
      //           Application.Flash.set(message, 'error');
      //         } else {
      //           Application.Flash.set('An unexpected error occurred.', 'error');
      //         }
      //       }
      //     });
      // });

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

        $('.sensitive-toggle-btn').off("click").on("click", function() {
            $('#sensitive-pane-content').toggleClass('d-none');
            $(this).toggleClass('expanded');
        });

        $('.contact-toggle-btn').off("click").on("click", function () {
            $('#contact-form').toggleClass('show');
            $(this).toggleClass('expanded');
            setToggleState($(this), $('#contact-form').hasClass('show'));
        });

        $(document).ajaxError(function(event, request, settings) {
            console.error(event);
            console.error(request);
            console.error(settings);
            console.trace();
        });
    },

    // /**
    //  * @return An object representing the current view.
    //  */
    view: null

};

$(document).ready(function(){
  var form = $('#contact-form')[0];
  if (form) {
    form.reset();
  }
  $('[data-toggle="tooltip"]').tooltip();
});

$(document).ready(function(){
  $('[data-bs-toggle="collapse"]').on('click', function() {
    var target = $(this).attr('href');
    $(target).collapse('toggle');
  });
});

$(document).ready(function(){
  function toggleSubmitButton() {
    var commentFilled = $('textarea[name="comment"]').val();
    var captchaFilled = $('#contact-answer').val();

    var commentFilled = commentFilled && commentFilled.trim() !== "";
    var captchaFilled = captchaFilled && captchaFilled.trim() !== "";

    if (commentFilled && captchaFilled) {
      $('#submit-button').prop('disabled', false);
    } else {
      $('#submit-button').prop('disabled', true);
    }
  }

  toggleSubmitButton();

  $('textarea[name="comment"], #contact-answer').on('input', function() {
    toggleSubmitButton();
  });

  $('#contact-form').on('submit', function(event) {
    var commentField = $('textarea[name="comment"]').val();
    var emailField = $('input[name="email"]').val();

    if (emailField.includes("@mail.ru")) {
      event.preventDefault();
    }
    if (commentField.includes("https://")) {
      event.preventDefault();
    }
  })
});

var ready = function() {
    Application.init();
};

$(document).ready(ready);
