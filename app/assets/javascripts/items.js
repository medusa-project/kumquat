/**
 * Encapsulates show-item view.
 *
 * @constructor
 */
const DLItemView = function() {

    var three_d_viewer_loaded = false;

    /**
     * Encapsulates the citation panel.
     *
     * @constructor
     */
    const CitationPanel = function() {

        const init = function() {
            Date.prototype.getAbbreviatedMonthName = function() {
                const monthNames = [
                    'Jan.', 'Feb.', 'Mar.', 'Apr.', 'May,', 'June',
                    'July', 'Aug.', 'Sept.', 'Oct.', 'Nov.', 'Dec.'
                ];
                return monthNames[this.getMonth()];
            };
            Date.prototype.getMonthName = function() {
                const monthNames = [
                  'January', 'February', 'March', 'April', 'May', 'June',
                  'July', 'August', 'September', 'October', 'November',
                  'December'
                ];
                return monthNames[this.getMonth()];
            };
            $('[name=dl-citation-format]').on('change', function() {
                var container = $(this).parent();
                var item_id = container.data('item-id');

                var author = container.find('[name=dl-citation-author]').val();
                var date = container.find('[name=dl-citation-date]').val();
                var date_created = container.find('[name=dl-citation-date-created]').val();
                var dateObj = new Date(date);
                var source = container.find('[name=dl-citation-source]').val();
                var title = container.find('[name=dl-citation-title]').val();
                var url = container.find('[name=dl-citation-url]').val();
                var collection = container.find('[name=dl-citation-collection]').val();
                var repo = container.find('[name=dl-citation-repository]').val();
                var citation = '';

                switch ($(this).val()) {
                    case 'APA':
                        // "Nonperiodical Web Document or Report":
                        // https://owl.english.purdue.edu/owl/resource/560/10/
                        // date should be date of item NOT date of creation?
                        if (author) {
                          if (author.charAt(author.length - 1) !== '.') {
                            author += '. ';
                        } else {
                          author += ' ';
                        }
                      }
                        if (!date) {
                            date = date_created;
                        }
                          
                        var formattedDate = '';
                        var month = dateObj.getAbbreviatedMonthName();
                        var day = dateObj.getDate();
                        var year = dateObj.getFullYear();

                        if (year) {
                          formattedDate = year.toString();
                        } else if (month && day && year) {
                            formattedDate = month + ' ' + day + ', ' + year;
                        } else if (month && year) {
                            formattedDate = month + ' ' + year;
                        } else if (day && year) {
                            formattedDate = day + ', ' + year;
                        } else {
                          formattedDate = 'n.d.';
                        }
                          date = '(' + formattedDate + '). ';
                          title = '<i>' + title + '</i>. ';
                          collection = collection + ', ';
                          url = url;
                          repo = ' ' + repo + ', ';
                          source = source + '. ';
                          citation = author + date + title + collection + repo + source + url;

                          if (!author) {
                              citation = author + title + date + collection + repo + source + url;
                          }
                        
                        break;
                    case 'Chicago':
                        // https://owl.english.purdue.edu/owl/resource/717/05/
                        if (author) {
                            author += ', ';
                        }

                        if (!date) {
                          date = date_created;
                        }
                          
                        var formattedDate = '';
                        var month = dateObj.getAbbreviatedMonthName();
                        var day = dateObj.getDate();
                        var year = dateObj.getFullYear();
                        
                        if (year) {
                          formattedDate = year.toString() + ', ';
                        } else if (month && day && year) {
                          formattedDate = month + ' ' + day + ', ' + year + ', ';
                        } else if (month && year) {
                          formattedDate = month + ' ' + year + ', ';
                        } else if (day && year) {
                          formattedDate = day + ', ' + year + ', ';
                        } else {
                          formattedDate = ' ';
                        }

                          
                          date = formattedDate + ' ';
                          url += '.';
                          title = '"' + title + '," ';
                          collection = collection + ', ';
                          source = source + ', ';
                          repo = ' ' + repo + ', ';
                          
                          citation = author + title + date + collection + repo + source + url;
                        
                        break;
                    case 'MLA':
                        // "A Page on a Web Site"
                        // https://owl.english.purdue.edu/owl/resource/747/08/
                        // CreatorName, TitleOfItem, DateOfItem, NameOfCollection, NAmeOfRepo, NAmeOfInst, URL
                        if (author) {
                          if (author.charAt(author.length - 1) !== '.') {
                            author += '. ';
                          } else {
                            author += ' ';
                          }
                        }

                        if (!date) {
                            date = date_created;
                        }
                      
                        var formattedDate = '';
                        var month = dateObj.getAbbreviatedMonthName();
                        var day = dateObj.getDate();
                        var year = dateObj.getFullYear();
                        
                        if (year) {
                          formattedDate = year.toString() + '. ';
                        
                        } else if (month && day && year) {
                          formattedDate = month + ' ' + day + ', ' + year + '. ';
                        } else if (month && year) {
                          formattedDate = month + ' ' + year + '. ';
                        } else if (day && year) {
                          formattedDate = day + ', ' + year + '. ';
                        } else {
                          formattedDate = 'Date Unknown. ';
                        }

                          date = formattedDate + ' ';
                          collection = collection + '. ';
                          source = source + '. ';
                          repo = ' ' + repo + ', ';
                          url = url.replace('http://', '').replace('https://', '') + '.';
                          title = ' ' + title + '. ';

                          citation = author + title + date + collection + repo + source + url;

                          break;
                }
                container.find('.dl-citation').html(citation);
            }).trigger('change');
        }; init();
    };

    /**
     * Encapsulates the embed-image panel.
     *
     * The panel is opened by an anchor with data-iiif-url, data-iiif-info-url,
     * and data-title attributes. The size and quality options are presented
     * dynamically based on the support declared by the image server in the
     * IIIF information response.
     *
     * @constructor
     */
    const CustomImagePanel = function() {

        const BYPASS_CACHE          = false;
        const MIN_IMAGE_SIZE        = 256;
        const NUM_BUTTON_SIZE_TIERS = 5;

        var imageUrl;
        var imageInfoUrl;
        var isModalLoaded = false;
        var title;

        const init = function() {
            const modal = $('#dl-custom-image-modal');
            
            if (modal.length === 0) {
                return;
            }
            
            // Add Bootstrap modal fallback if not available
            if (!$.fn.modal) {
                $.fn.modal = function(action) {
                    if (action === 'show') {
                        this.removeClass('fade').addClass('show').css('display', 'block');
                        $('body').addClass('modal-open');
                        if (!$('.modal-backdrop').length) {
                            $('body').append('<div class="modal-backdrop fade show"></div>');
                        }
                    } else if (action === 'hide') {
                        this.removeClass('show').css('display', 'none');
                        $('body').removeClass('modal-open');
                        $('.modal-backdrop').remove();
                    }
                    return this;
                };
            }
            
            modal.on('show.bs.modal', function(e) {
                const clicked_button = $(e.relatedTarget);
                title        = clicked_button.data('title').trim().replace(/"/g, '&quot;');
                imageUrl     = clicked_button.data('iiif-url');
                imageInfoUrl = clicked_button.data('iiif-info-url');
                if (BYPASS_CACHE) {
                    imageInfoUrl += "?cache=recache";
                }

                $.ajax({
                    dataType: 'json',
                    url:      imageInfoUrl,
                    data:     null,
                    success:  function(data) {
                        renderContents(data);
                    },
                    error: function(xhr, status, error) {
                        renderError();
                    }
                });
                isModalLoaded = true;
            });
            
            // Fallback: Handle button clicks directly if Bootstrap modal events don't work
            $('body').on('click', '[data-target="#dl-custom-image-modal"]', function(e) {
                e.preventDefault();
                
                var button = $(this);
                title        = button.data('title');
                imageUrl     = button.data('iiif-url');
                imageInfoUrl = button.data('iiif-info-url');
                
                if (title && imageUrl && imageInfoUrl) {
                    title = title.trim().replace(/"/g, '&quot;');
                    if (BYPASS_CACHE) {
                        imageInfoUrl += "?cache=recache";
                    }
                    
                    $.ajax({
                        dataType: 'json',
                        url:      imageInfoUrl,
                        data:     null,
                        success:  function(data) {
                            renderContents(data);
                            modal.modal('show');
                        },
                        error: function(xhr, status, error) {
                            renderError();
                            modal.modal('show');
                        }
                    });
                    isModalLoaded = true;
                }
                
                return false;
            });
            
            // Handle modal close buttons when Bootstrap JS isn't available
            $('body').on('click', '[data-dismiss="modal"]', function(e) {
                e.preventDefault();
                var targetModal = $(this).closest('.modal');
                if (targetModal.length) {
                    targetModal.modal('hide');
                }
                return false;
            });
        }; init();

        const renderError = function() {
            const container = $('#iiif-download');
            container.empty();
            container.append(
                '<div class="alert alert-danger">' +
                    '<i class="fas fa-exclamation-triangle"></i> ' +
                    'Sorry, this image is not available for custom download. ' +
                    'Please try the "Original File" download instead.' +
                '</div>'
            );
        };

        const renderContents = function(info) {
            const container = $('#iiif-download');
            container.empty();
            const fullWidth = info['width'];
            const numSizes  = info['sizes'].length;
            const maxPixels = info['profile'][1]['maxArea'];

            // Find the number of usable sizes (i.e. sizes above MIN_IMAGE_SIZE
            // and below maxPixels) in order to calculate button size tiers.
            var numUsableSizes = 0;
            for (let i = 0; i < numSizes; i++) {
                const width  = info['sizes'][i]['width'];
                const height = info['sizes'][i]['height'];
                if (width >= MIN_IMAGE_SIZE && height >= MIN_IMAGE_SIZE
                    && width * height <= maxPixels) {
                    numUsableSizes++;
                }
            }

            // Create a button for each size tier from the maximum down to
            // the minimum.
            for (i = numSizes - 1, size_i = numSizes - 1; i >= 0; i--) {
                const width   = info['sizes'][i]['width'];
                const height  = info['sizes'][i]['height'];
                if (width >= MIN_IMAGE_SIZE && height >= MIN_IMAGE_SIZE && width * height <= maxPixels) {
                    const sizeClass = 'dl-size-' + Math.floor(size_i / numUsableSizes * NUM_BUTTON_SIZE_TIERS);
                    const percent = Math.round(width / fullWidth * 100);
                    const checked = (size_i === numSizes - 1) ? 'checked' : '';
                    const active  = (size_i === numSizes - 1) ? 'active' : '';
                    const id = 'size-' + width + '-' + height;
                    const labelText = width + '\u00D7' + height + ' pixels (' + percent + '%)';
                    container.append(
                        '<div class="radio ' + sizeClass + ' ' + active + '">' +
                        '<input type="radio" name="size" id="' + id + '" value="' + width + '," ' + checked + '>' +
                        '<label for="' + id + '" class="btn btn-outline-primary">' + labelText + '</label>' +
                        '</div><br>');
                    size_i--;
                }
            }

            container.append('<hr>');

            const qualitiesDiv = $('<div class="form-inline"></div>');
            info['profile'][1]['qualities'].forEach(function (item) {
                // Exclude the "default" quality.
                if (item === 'color' || item === 'gray' || item === 'bitonal') {
                    var checked = '';
                    var containerClass = '';
                    if (item === 'color') {
                        checked = 'checked';
                        containerClass = 'active';
                    }
                    var id = 'quality-' + item;
                    var labelText = item.charAt(0).toUpperCase() + item.slice(1);
                    qualitiesDiv.append(
                        '<div class="radio ' + containerClass + '">' +
                            '<input type="radio" name="quality" id="' + id + '" value="' + item + '" ' + checked + '>' +
                            '<label for="' + id + '" class="btn btn-outline-primary">' + labelText + '</label>' +
                        '</div>');
                }
            });
            container.append(qualitiesDiv);
            container.append('<hr>');

            const formatsDiv = $('<div class="form-inline"></div>');
            info['profile'][1]['formats'].forEach(function (item) {
                var checked = '';
                var containerClass = '';
                if (item === 'jpg') {
                    checked        = 'checked';
                    containerClass = 'active';
                }
                var id = 'format-' + item;
                var labelText = item.toUpperCase();
                if (labelText === 'JPG') {
                    labelText = 'JPEG';
                } else if (labelText === 'TIF') {
                    labelText = 'TIFF';
                }
                formatsDiv.append(
                    '<div class="radio ' + containerClass + '">' +
                        '<input type="radio" name="format" id="' + id + '" value="' + item + '" ' + checked + '>' +
                        '<label for="' + id + '" class="btn btn-outline-primary">' + labelText + '</label>' +
                    '</div>');
            });
            container.append(formatsDiv);

            const modal = $('#dl-custom-image-modal');

            const displayUrl = function() {
                const size    = modal.find('input[name="size"]:checked').val();
                const quality = modal.find('input[name="quality"]:checked').val();
                const format  = modal.find('input[name="format"]:checked').val();
                const url     = imageUrl + '/full/' + size + '/0/' + quality + '.' + format;
                $('#dl-preview-link').attr('href', url).show();
                $('#dl-embed-link').val('<img src="' + url + '" alt="' + title + '">');
            };

            $('input[name="size"], input[name="quality"], input[name="format"]').on('click', function () {
                displayUrl();
            });
            displayUrl();

            const radios = modal.find('input[type=radio]');
            radios.on('click', function () {
                radios.each(function () {
                    const radio_container = $(this).parents('div.radio');
                    if ($(this).is(':checked')) {
                        radio_container.addClass('active');
                    } else {
                        radio_container.removeClass('active');
                    }
                });
            });
        }
    };

    this.init = function() {
        // Add Bootstrap collapse fallback if not available
        if (!$.fn.collapse) {
            $.fn.collapse = function(action) {
                if (action === 'show') {
                    this.removeClass('collapse').addClass('collapse show');
                    // Trigger custom events
                    this.trigger('show.bs.collapse').trigger('shown.bs.collapse');
                } else if (action === 'hide') {
                    this.removeClass('show').addClass('collapse');
                    // Trigger custom events
                    this.trigger('hide.bs.collapse').trigger('hidden.bs.collapse');
                } else if (action === 'toggle') {
                    if (this.hasClass('show')) {
                        this.removeClass('show');
                        this.trigger('hide.bs.collapse').trigger('hidden.bs.collapse');
                    } else {
                        this.addClass('show');
                        this.trigger('show.bs.collapse').trigger('shown.bs.collapse');
                    }
                }
                return this;
            };
        }
        
        $('#dl-download-button').on('click', function() {
            $('#dl-download').collapse('show');
            const container = $('html, body');
            const offset    = $('#dl-download-section').offset().top;
            container.animate({ scrollTop: offset }, Application.SCROLL_SPEED);
            return false;
        });
        $('#dl-more-information-button').on('click', function() {
            $('#dl-metadata').collapse('show');
            const container = $('html, body');
            const offset    = $('#dl-metadata-section').offset().top;
            container.animate({ scrollTop: offset }, Application.SCROLL_SPEED);
            return false;
        });

        // Add an expander icon in front of every collapse toggle.
        const toggleForCollapse = function(collapse) {
            return collapse.prev().find('a[data-toggle="collapse"]:first');
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

        // In free-form item view, when a section is expanded or collapsed, the
        // tree browser's height must be updated to fit.
        const freeFormItemView = $('#dl-free-form-item-view');
        if (freeFormItemView.length > 0) {
            collapses.on('shown.bs.collapse hidden.bs.collapse', function() {
                const lastElem = freeFormItemView.children().filter(':visible').filter(':last');
                const height   = lastElem.offset().top + lastElem.height() - 200;
                $('#dl-free-form-tree-view').css('height', height);
            });
        }

        // Lazy-load thumbnail images in the download section when it gets
        // expanded.
        $('#dl-download-section').on('shown.bs.collapse', function() {
            Application.loadLazyImages();
        });
        // Or, when it's being rendered in its expanded state.
        if ($('#dl-download').hasClass('show')) {
            $('#dl-download-section').trigger('shown.bs.collapse');
        }

        // The 3D viewer is initially not loaded. Load it the first time its
        // container div appears.
        $('#dl-3d-viewer-container').on('shown.bs.collapse', function() {
            if (!three_d_viewer_loaded) {
                Application.view.threeDViewer.start();
                three_d_viewer_loaded = true;
            }
        });

        var initial_index = $('[name=dl-download-item-index]').val();

        // Initialize Universal Viewer v4.0.25
        var uvElement = document.getElementById('dl-compound-viewer') || document.getElementById('dl-image-viewer');
        if (uvElement && typeof UV !== 'undefined') {
            try {
                // Get the manifest URI and config from HTML data attributes
                var manifestUri = uvElement.getAttribute('data-uri');
                var configUri = uvElement.getAttribute('data-config');
                var locale = uvElement.getAttribute('data-locale') || 'en-GB';
                var sequenceIndex = parseInt(uvElement.getAttribute('data-sequenceindex') || '0');
                var canvasIndex = parseInt(uvElement.getAttribute('data-canvasindex') || '0');
                var rotation = parseInt(uvElement.getAttribute('data-rotation') || '0');
                
                var uv;
                
                // Handle different viewer types differently
                if (uvElement.id === 'dl-image-viewer') {
                    console.log('Initializing single image viewer');
                    // For single image viewers, provide manifest data directly
                    var data = {
                        manifest: manifestUri,
                        embedded: false,
                        canvasIndex: canvasIndex,
                        rotation: rotation
                    };
                    console.log('Single image viewer data:', data);
                    uv = UV.init(uvElement.id, data);
                    
                } else if (uvElement.id === 'dl-compound-viewer') {
                    console.log('Initializing compound viewer with direct data');
                    // For compound viewers, provide manifest data directly like single images
                    var data = {
                        manifest: manifestUri,
                        embedded: false,
                        canvasIndex: canvasIndex,
                        sequenceIndex: sequenceIndex,
                        rotation: rotation
                    };
                    console.log('Compound viewer data:', data);
                    uv = UV.init(uvElement.id, data);
                }
                
                // Configure UV to load config file
                uv.on("configure", function({ config, cb }) {
                    cb(
                        new Promise(function (resolve) {
                            fetch(configUri).then(function (response) {
                                resolve(response.json());
                            });
                        })
                    );
                });
                
                console.log('Universal Viewer v4.0.25 initialized successfully');
            } catch (error) {
                console.error('UV initialization failed:', error);
            }
        }

        // This acts as both a canvas-index-changed and on-load-complete
        // listener, because UV doesn't have the latter, unless I'm missing
        // something:
        $(document).bind('uv.onCanvasIndexChanged', function(event, index) {
            // Select the item in the viewer corresponding to the current URL.
            if (initial_index) {
                console.debug("Initially selected index: " + initial_index);
                index = initial_index;
                // UV doesn't have a "selectCanvasIndex(index)" method as of
                // version 2.0. We can't do this quite yet but there is no
                // event to let us know when it's safe, hence the delay.
                setTimeout(function() {
                    $('#dl-compound-viewer iframe').contents()
                        .find('div#thumb' + index + ' img').trigger('click');
                    initial_index = null;
                }, 500);
            }

            console.debug('Selected canvas index: ' + index);

            // When there are >1 items in the viewer:
            // (N.B. The viewer and the download table will always contain the
            // same items in the same order.)
            const rows = $('#dl-download table tr');
            if (rows.length > 1) {
                // Highlight the corresponding item in the download table.
                // (UV will also fire this on load.)
                rows.removeClass('selected')
                    .filter(':nth-child(' + (index + 1) + ')')
                    .addClass('selected');

                // Update the URL in the location bar.
                const item_id = $('[name=dl-download-item-id]').eq(index).val();
                window.history.replaceState({ id: item_id, index: index }, '',
                    '/items/' + item_id);
            }
        });

        // Copy the permalink to the clipboard when a copy-permalink button is
        // clicked. This uses clipboard.js: https://clipboardjs.com
        const clipboard = new Clipboard('.dl-copy-permalink');
        clipboard.on('success', function(e) {
            // Remove the button and add a "copied" message in its place.
            const button = $(e.trigger);
            button.parent().append('<small>' +
                    '<span class="text-success">' +
                        '<i class="fa fa-check"></i> Copied' +
                    '</span>'+
                '</small>');
            button.remove();
        });
        clipboard.on('error', function(e) {
            console.error('Action:', e.action);
            console.error('Trigger:', e.trigger);
        });

        new CitationPanel();
        new CustomImagePanel();
        new Application.CaptchaProtectedDownload();

    $(document).ready(function(){
      function toggleSubmitButton() {
        var commentFilled = $('textarea[name="comment"]').val();
        var captchaField = $('#contact-answer');
        var captchaFilled = captchaField.val();

        console.log('Comment:', commentFilled);
        console.log('Captcha Field:', captchaField);
        console.log('Captcha Field Exists:', captchaField.length > 0);
        console.log('Captcha Value:', captchaFilled);

        var commentFilled = commentFilled && commentFilled.trim() !== "";
        var captchaFilled = captchaFilled && captchaFilled.trim() !== "";

        if (commentFilled && captchaFilled) {
          $('#submit-button').prop('disabled', false);
        } else {
          $('#submit-button').prop('disabled', true);
        }
      }

      toggleSubmitButton();

      $('textarea[name="comment"], #contact-answer').on('input', function () {
        console.log('Input event triggered');
        toggleSubmitButton();
      });

      // Ensure the form is reset when the document is ready
      var formElement = document.getElementById('contact-form');
      if (formElement && typeof formElement.reset === 'function') {
        console.log('Resetting contact form');
        formElement.reset();
      } else {
        console.log('Contact form not found or reset not available');
      }

    });

    };

};

/**
 * Handles linear items view, a.k.a. results view.
 *
 * @constructor
 */
const DLItemsView = function() {

    const CURRENT_PATH = $('[name=dl-current-path]').val();
    const filterForm   = $("form.dl-filter");
    const self         = this;

    this.init = function() {
        new Application.CaptchaProtectedDownload();
        new Application.FilterField();
        self.attachEventListeners();
    };

    const getSerializedCanonicalFormQuery = function() {
        return filterForm.find(':not([name=collection_id], [name=dl-facet-term])')
            .serialize();
    };

    this.attachEventListeners = function() {
        Application.initThumbnails();
        Application.initFacets();

        filterForm.find('select[name="sort"]').off().on("change", function() {
            onSortMenuChanged();
        });
        filterForm.find('.page-link').off().on("click", function() {
            filterForm.scrollIntoView({behavior: "smooth", block: "start"});
            onPageLinkClicked($(this));
        });
    };

    this.restoreState = function() {
        var query = window.location.hash;
        if (query.length) {
            query = query.substring(1); // trim off the `#`
            console.debug('restoreState(): ' + query);
            $.ajax({
                url:      CURRENT_PATH,
                method:   'GET',
                data:     query,
                dataType: 'script',
                success: function (result) {
                    eval(result);
                }
            });
        }
    };

    const onPageLinkClicked = function(link) {
        const url = link.attr('href');
        var query = "";
        const queryIndex = url.indexOf("?");
        if (queryIndex >= 0) {
            query = url.substring(queryIndex + 1);
        }
        $.ajax({
            url:      url,
            method:   'GET',
            dataType: 'script',
            success:  function(result) {
                window.location.hash = query;
                eval(result);
            }
        });
        return false;
    };

    const onSortMenuChanged = function() {
        const query = getSerializedCanonicalFormQuery();
        $.ajax({
            url:      CURRENT_PATH,
            method:   'GET',
            data:     query,
            dataType: 'script',
            success: function (result) {
                window.location.hash = query;
                eval(result);
            }
        });
    };

};

/**
 * Handles free-form tree view.
 *
 * @constructor
 */
const DLTreeBrowserView = function() {

    const NODE_SELECTION_DELAY = 600;

    this.init = function() {
        initializeSplitView();
        initializeTree();
    };

    const initializeSplitView = function() {
        const leftSide  = document.querySelector("#dl-free-form-tree-view");
        const splitter  = document.querySelector("#dl-splitter");
        const rightSide = document.querySelector("#dl-free-form-item-view");

        let x = 0, y = 0, leftWidth = 0;

        const onMouseDown = function (e) {
            x         = e.clientX;
            y         = e.clientY;
            leftWidth = leftSide.getBoundingClientRect().width;
            document.addEventListener('mousemove', onMouseMove);
            document.addEventListener('mouseup', onMouseUp);
        };

        const onMouseMove = function(e) {
            e.preventDefault();
            const dx                      = e.clientX - x;
            const newLeftWidth            = ((leftWidth + dx) * 100) /
                splitter.parentNode.getBoundingClientRect().width;
            leftSide.style.width          = `${newLeftWidth}%`;
            leftSide.style.userSelect     = 'none';
            leftSide.style.pointerEvents  = 'none';
            rightSide.style.userSelect    = 'none';
            rightSide.style.pointerEvents = 'none';
            document.body.style.cursor = 'col-resize';
        };

        const onMouseUp = function() {
            document.body.style.removeProperty('cursor');
            splitter.style.removeProperty('cursor');
            leftSide.style.removeProperty('user-select');
            leftSide.style.removeProperty('pointer-events');
            rightSide.style.removeProperty('user-select');
            rightSide.style.removeProperty('pointer-events');
            document.removeEventListener('mousemove', onMouseMove);
            document.removeEventListener('mouseup', onMouseUp);
        };

        splitter.addEventListener('mousedown', onMouseDown);
    };

    /**
     * @see https://www.jstree.com/api/#/
     */
    const initializeTree = function() {
        const target_id = window.location.hash.substring(1);

        const jstree = $('#dl-free-form-tree-view');
        if (jstree.length > 0) {
            // Enable the "tree help" popover unless the browser has already
            // seen it.
            const hideTreeHelp = Cookies.get('hide_tree_popover');
            if (!hideTreeHelp) {
                jstree.popover("toggle");
                $(".popover .btn").on("click", function () {
                    jstree.popover("dispose");
                    Cookies.set('hide_tree_popover', true);
                });
            }

            jstree.jstree({
                core: {
                    dblclick_toggle: false,
                    multiple: false,
                    data: {
                        url: function (node) {
                            return node.id === '#' ?
                                getRootTreeDataURL() :
                                '/items/' + node.id + '/treedata.json';
                        }
                    }
                }
            }).bind('ready.jstree', function() {
                // When we are entering the view, it may be to a URL like:
                // /collections/:id/tree#:item_id
                // If :item_id is present, we need to rewrite the URL as:
                // /items/:id and traverse the tree to the node corresponding
                // to that ID.
                if (target_id) {
                    drillDownToID(target_id);
                }
            }).bind("select_node.jstree", function (e, data) {
                retrieveItemView(buildAjaxNodeURL(data));

                // Add the selected item ID to the hash portion of the URL.
                console.debug('Navigating to ' + data.node.id);
                window.history.replaceState({id: data.node.id}, '',
                    buildPublicNodeURL(data));
            }).bind("click", '.jstree-anchor', function (e) {
                // We want to toggle node expansion/contraction on single click.
                // This works in conjunction with the
                // `core.dblclick_toggle: false` that we did above.
                // A click may hit the main node a, the a > i to which the icon
                // is attached, or the node expansion button to the left of the
                // icon. We want to ignore the latter case,
                if (e.target.tagName == "A" ||
                    (e.target.tagName == "I" && $(e.target).parent().hasClass("directory_node"))) {
                    jstree.jstree(true).toggle_node(e.target);
                }
            });

            jstree.on('ready.jstree open_node.jstree select_node.jstree', function() {
                $(this).find('.jstree-anchor:visible').attr('tabindex', '0');
            });

            // DLD-132: when an arrow key is used to change the tree selection,
            // the selected item should load without having to press enter.
            // jstree provides a hover_node event, but it doesn't distinguish
            // between input methods, so we have to do this manually.
            // We also do the selection on a cancellable timer so that closely
            // spaced key presses don't fire off a flurry of AJAX requests.
            var timeoutID;
            $(document).on('keyup', function(e) {
                if (e.which === 38 || e.which === 40) { // arrow up or down
                    var activeElement = $(document.activeElement);
                    if (activeElement.hasClass('jstree-hovered')) {
                        clearInterval(timeoutID);
                        timeoutID = setTimeout(function () {
                            jstree.jstree('deselect_all');
                            jstree.jstree('select_node', '#' +
                                activeElement.parent().attr('id'));
                        }, NODE_SELECTION_DELAY);
                    }
                }
            });

            if (!target_id) {
                retrieveItemView('/collections/' +
                    window.location.pathname.split("/")[2] + '/tree.html?ajax=true');
            }
        }
    };

    /**
     * Drills down through the tree to the leaf node corresponding to the item
     * with the given ID.
     *
     * @param id Item ID.
     */
    const drillDownToID = function(id) {
        console.debug("Drilling down to ID " + id);

        /**
         * Recursive function that drills down the tree to a specific leaf
         * node.
         *
         * @param nodes Array of node IDs in order from root to leaf.
         * @param level Used internally; supply 0 to start.
         * @param onComplete Callback function.
         */
        const drillDown = function(nodes, level, onComplete) {
            var jstree = $('#dl-free-form-tree-view');
            if (level < nodes.length) {
                var id = nodes[level];
                jstree.jstree('open_node', '#' + id, function() {
                    level += 1;
                    drillDown(nodes, level, onComplete);
                });
            } else {
                onComplete();
            }
        };

        /**
         * Assembles a list of parent IDs of the given item ID,
         * which is passed to the callback function.
         *
         * @param id Item ID.
         * @param parents Array of parents. Supply an empty array
         *                to start.
         * @param onComplete Callback function.
         */
        const traceLineage = function(id, parents, onComplete) {
            console.debug('Finding parent of ' + id);
            $.ajax({
                url: '/items/' + id + '.json',
                dataType: 'json',
                method: 'GET',
                success: function(result) {
                    if (result.parent_uri) {
                        var parts = result.parent_uri.split('/');
                        var parent = parts[parts.length - 1].replace('.json', '');
                        console.debug('Parent of ' + id + ' is ' + parent);
                        parents.push(parent);
                        traceLineage(parent, parents, onComplete);
                    } else {
                        onComplete(parents.reverse());
                    }
                }
            });
        };

        traceLineage(id, [], function(parents) {
            drillDown(parents, 0, function() {
                const jstree = $('#dl-free-form-tree-view');
                jstree.jstree('deselect_all');
                jstree.jstree('select_node', '#' + id);
                window.history.replaceState({id: id}, '', '/items/' + id);
                console.debug('Drill-down complete');
            });
        });
    };

    const buildAjaxNodeURL = function(data) {
        if (data.node.a_attr["name"] === 'root-collection-node') {
            return '/collections/' + data.node.id + '/tree.html?ajax=true';
        }
        return '/items/' + data.node.id + '.html?tree-node-type=' +
            data.node.a_attr["class"];
    };

    const buildPublicNodeURL = function(data) {
        var url;
        if (data.node.a_attr.class.includes('Collection')) {
            url = '/collections/' + data.node.id + '/tree'
        } else {
            url = '/items/' + data.node.id
        }
        return url;
    }

    const treeView = $('#dl-free-form-item-view');

    const updateItemViewHeight = function() {
        const lastElem = treeView.children().filter(':visible').filter(':last');
        const height   = lastElem.offset().top + lastElem.height() - 200;
        $('#dl-free-form-split-pane').css('height', height);
    }

    const setItemViewHTML = function(result) {
        //reset flag used by embed.js
        window.embedScriptIncluded = false;
        treeView.html(result);
        Application.init();
        Application.view = new DLItemView();
        Application.view.init();
        updateItemViewHeight();
    };

    const getRootTreeDataURL = function() {
        const ID = window.location.pathname.split("/")[2];
        return '/collections/' + ID + '/items/treedata.json';
    };

    const retrieveItemView = function(ajax_url) {
        $.ajax({
            url: ajax_url,
            method: 'GET',
            success: function(result) {
                setItemViewHTML(result);
            }
        });
    };

};

$(document).ready(function() {
    if ($('body#tree_browser').length) {
        Application.view = new DLTreeBrowserView();
        Application.view.init();
    } if ($('body#items_index').length) {
        Application.view = new DLItemsView();
        Application.view.init();
    } else if ($('body#items_show').length) {
        Application.view = new DLItemView();
        Application.view.init();
    }
});

/**
 * When the page is shown, restore page state based on the query embedded in
 * the hash. This has to be done on pageshow because document.ready doesn't
 * fire on back/forward.
 */
$(window).on("pageshow", function(event) {
    if ($('body#items_index').length && !event.originalEvent.persisted) {
        Application.view = new DLItemsView();
        Application.view.restoreState();
    }
});

document.addEventListener('fullscreenchange', function() {
  if (!document.fullscreenElement) {
    setTimeout(function() {
      var viewer = document.getElementById('dl-compound-viewer') || document.getElementById('dl-image-viewer');
      if (viewer) {
        viewer.style.cssText = 'height: 650px; background-color: black; margin: 0 auto;';


        var iframe = viewer.querySelector('iframe');
        if (iframe) {
          iframe.style.cssText = 'width: 100%; height: 650px;';

          void viewer.offsetHeight;
        }
      }
    }, 100);
  }
});


document.addEventListener('webkitfullscreenchange', function() {});
document.addEventListener('mozfullscreenchange', function() {});
document.addEventListener('MSFullscreenChange', function() {});
