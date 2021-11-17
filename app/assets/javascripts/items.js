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

        var init = function() {
            Date.prototype.getAbbreviatedMonthName = function() {
                switch (this.getMonth()) {
                    case 1: return 'Jan.';
                    case 2: return 'Feb.';
                    case 3: return 'Mar.';
                    case 4: return 'Apr.';
                    case 5: return 'May';
                    case 6: return 'June';
                    case 7: return 'July';
                    case 8: return 'Aug.';
                    case 9: return 'Sept.';
                    case 10: return 'Oct.';
                    case 11: return 'Nov.';
                    case 12: return 'Dec.';
                }
            };
            Date.prototype.getMonthName = function() {
                switch (this.getMonth()) {
                    case 1: return 'January';
                    case 2: return 'February';
                    case 3: return 'March';
                    case 4: return 'April';
                    case 5: return 'May';
                    case 6: return 'June';
                    case 7: return 'July';
                    case 8: return 'August';
                    case 9: return 'September';
                    case 10: return 'October';
                    case 11: return 'November';
                    case 12: return 'December';
                }
            };
            $('[name=dl-citation-format]').on('change', function() {
                var container = $(this).parent();
                var item_id = container.data('item-id');

                var author = container.find('[name=dl-citation-author]').val();
                var date = container.find('[name=dl-citation-date-created]').val();
                var dateObj = new Date(date);
                var source = container.find('[name=dl-citation-source]').val();
                var title = container.find('[name=dl-citation-title]').val();
                var url = container.find('[name=dl-citation-url]').val();
                var citation = '';

                switch ($(this).val()) {
                    case 'APA':
                        // "Nonperiodical Web Document or Report":
                        // https://owl.english.purdue.edu/owl/resource/560/10/
                        if (author) {
                            author += '. ';
                        } else {
                            author = '[Unknown]. ';
                        }
                        if (date) {
                            date = '(' + dateObj.getFullYear() + ', ' +
                                dateObj.getMonthName() + ' ' + dateObj.getDay() + '). ';
                        }
                        title = '<i>' + title + '</i>. ';
                        url = 'Retrieved from ' + url;
                        citation = author + date + title + url;
                        break;
                    case 'Chicago':
                        // https://owl.english.purdue.edu/owl/resource/717/05/
                        if (author) {
                            author += ', ';
                        }
                        title = '"' + title + '," ';
                        source = '<i>' + source + '</i>, ';
                        date = 'last modified ' + dateObj.getMonthName() +
                            ' ' + dateObj.getDay() + ', ' +
                            dateObj.getFullYear() + ', ';
                        url += '.';
                        citation = author + title + source + date + url;
                        break;
                    case 'MLA':
                        // "A Page on a Web Site"
                        // https://owl.english.purdue.edu/owl/resource/747/08/
                        title = '"' + title + '." ';
                        source = '<i>' + source + ',</i> ';
                        date = dateObj.getDay() + ' ' +
                            dateObj.getAbbreviatedMonthName() + ' ' +
                            dateObj.getFullYear() + ', ';
                        url = url.replace('http://', '').replace('https://', '') + '.';
                        citation = title + source + date + url;
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
            modal.on('show.bs.modal', function(e) {
                // Get the element that was clicked to open the panel.
                const clicked_button = $(e.relatedTarget);
                // Read its relevant data attributes.
                title        = clicked_button.data('title').trim().replace(/"/g, '&quot;');
                imageUrl     = clicked_button.data('iiif-url');
                imageInfoUrl = clicked_button.data('iiif-info-url');
                if (BYPASS_CACHE) {
                    imageInfoUrl += "?cache=recache";
                }

                // Load the image's IIIF info.
                $.ajax({
                    dataType: 'json',
                    url:      imageInfoUrl,
                    data:     null,
                    success:  function(data) {
                        renderContents(data);
                    }
                });
                isModalLoaded = true;
            });
        }; init();

        const renderContents = function(info) {
            const container = $('#iiif-download');
            container.empty();
            const fullWidth = info['width'];
            const numSizes  = info['sizes'].length;
            const maxPixels = info['profile'][1]['maxArea'];

            // Find the number of usable sizes (i.e. sizes above MIN_IMAGE_SIZE
            // and below maxPixels) in order to calculate button size tiers.
            var numUsableSizes = 0;
            for (var i = 0; i < numSizes; i++) {
                const width  = info['sizes'][i]['width'];
                const height = info['sizes'][i]['height'];
                if (width >= MIN_IMAGE_SIZE && height >= MIN_IMAGE_SIZE
                    && width * height <= maxPixels) {
                    numUsableSizes++;
                }
            }

            // Create a button for each size tier from the maximum down to
            // the minimum.
            for (var i = numSizes - 1, size_i = numSizes - 1; i >= 0; i--) {
                const width   = info['sizes'][i]['width'];
                const height  = info['sizes'][i]['height'];

                if (width >= MIN_IMAGE_SIZE && height >= MIN_IMAGE_SIZE
                    && width * height <= maxPixels) {
                    const sizeClass = 'dl-size-' +
                        Math.floor(size_i / numUsableSizes * NUM_BUTTON_SIZE_TIERS);
                    const percent = Math.round(width / fullWidth * 100);
                    const checked = (size_i === numSizes - 1) ? 'checked' : '';
                    const active  = (size_i === numSizes - 1) ? 'active' : '';
                    const label   = width + '&times;' + height + ' pixels (' + percent + '%)';
                    container.append(
                        '<div class="radio btn btn-outline-primary ' + sizeClass + ' ' + active + '">' +
                        '<label>' +
                        '<input type="radio" name="size" value="' + width + ',' + '" ' + checked + '>' +
                        label +
                        '</label>' +
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
                    qualitiesDiv.append(
                        '<div class="radio btn btn-outline-primary ' + containerClass + '">' +
                            '<label>' +
                                '<input type="radio" name="quality" value="' + item + '" ' + checked + '>' +
                                item.charAt(0).toUpperCase() + item.slice(1) +
                            '</label>' +
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
                var label = item.toUpperCase();
                if (label === 'JPG') {
                    label = 'JPEG';
                } else if (label === 'TIF') {
                    label = 'TIFF';
                }
                formatsDiv.append(
                    '<div class="radio btn btn-outline-primary ' + containerClass + '">' +
                        '<label>' +
                            '<input type="radio" name="format" value="' + item + '" ' + checked + '>' +
                            label +
                        '</label>' +
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
        $('#dl-download-button').on('click', function() {
            $('#dl-download').collapse('show');
            var container = $('html, body');
            var offset    = $('#dl-download-section').offset().top;
            container.animate({ scrollTop: offset }, Application.SCROLL_SPEED);
            return false;
        });
        $('#dl-more-information-button').on('click', function() {
            $('#dl-metadata').collapse('show');
            var container = $('html, body');
            var offset    = $('#dl-metadata-section').offset().top;
            container.animate({ scrollTop: offset }, Application.SCROLL_SPEED);
            return false;
        });

        // Add an expander icon in front of every collapse toggle.
        const toggleForCollapse = function(collapse) {
            return collapse.prev().find('a[data-toggle="collapse"]:first');
        };
        const setToggleState = function(elem, expanded) {
            elem.find('img').css('transform', expanded ? 'rotate(90deg)' : 'rotate(270deg)');
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
                $('#jstree').css('height', height);
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
        new Application.Captcha();
    };

};

/**
 * Handles linear items view, a.k.a. results view.
 *
 * @constructor
 */
const DLItemsView = function() {

    const self = this;

    this.init = function() {
        new Application.Captcha();
        new Application.FilterField();
        Application.initFacets();

        // Submit the sort form on change.
        $('select[name="sort"]').off().on('change', function () {
            var query = $(this).parents('form:first')
                .find(':not(input[name=collection_id])').serialize();
            $.ajax({
                url: $('[name=dl-current-path]').val(),
                method: 'GET',
                data: query,
                dataType: 'script',
                success: function (result) {
                    // Enables results page persistence after back/forward
                    // navigation.
                    window.location.hash = query;
                    eval(result);
                }
            });
        });

        // Override Rails' handling of link_to() with `remote: true` option.
        // We are doing the same thing but also updating the hash.
        $('.page-link').on('click', function() {
            var url   = $(this).attr('href');
            var query = url.substring(url.indexOf("?") + 1);
            $.ajax({
                url: url,
                method: 'GET',
                dataType: 'script',
                success: function(result) {
                    window.location.hash = query;
                    eval(result);
                }
            });
            return false;
        });

        self.attachEventListeners();
    };

    /**
     * This needs to be public as it's called from index.js.
     */
    this.attachEventListeners = function() {
        Application.initThumbnails();

        $('.pagination a').on('click', function() {
            $('form.dl-filter')[0].scrollIntoView({behavior: "smooth", block: "start"});
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
        initializeTree();
    };

    /**
     * @see https://www.jstree.com/api/#/
     */
    const initializeTree = function() {
        const target_id = window.location.hash.substring(1);

        const jstree = $('#jstree');
        if (jstree.length > 0) {
            jstree.jstree({
                core: {
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
        var drillDown = function(nodes, level, onComplete) {
            var jstree = $('#jstree');
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
        var traceLineage = function(id, parents, onComplete) {
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
                const jstree = $('#jstree');
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

    const setItemViewHTML = function(result) {
        //reset flag used by embed.js
        window.embedScriptIncluded = false;
        const treeView = $('#dl-free-form-item-view');
        treeView.html(result);
        Application.init();
        Application.view = new DLItemView();
        Application.view.init();

        // Update the height of the tree browser to fit.
        const lastElem = treeView.children().filter(':visible').filter(':last');
        const height   = lastElem.offset().top + lastElem.height() - 200;
        $('#jstree').css('height', height);
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
        var query = window.location.hash;
        if (query.length) {
            query = query.substring(1); // trim off the `#`
            console.debug('Restoring ' + query);
            $.ajax({
                url: $('[name=dl-current-path]').val(),
                method: 'GET',
                data: query,
                dataType: 'script',
                success: function (result) {
                    eval(result);
                }
            });
        }
    }
});
