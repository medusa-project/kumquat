/**
 * Encapsulates show-item view.
 *
 * @constructor
 */
var PTItemView = function() {

    var three_d_viewer_loaded = false;

    var self = this;

    /**
     * Encapsulates the citation panel.
     *
     * @constructor
     */
    var PTCitationPanel = function() {

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
            $('[name=pt-citation-format]').on('change', function() {
                var container = $(this).parent();
                var item_id = container.data('item-id');

                var author = container.find('[name=pt-citation-author]').val();
                var date = container.find('[name=pt-citation-date-created]').val();
                var dateObj = new Date(date);
                var source = container.find('[name=pt-citation-source]').val();
                var title = container.find('[name=pt-citation-title]').val();
                var url = container.find('[name=pt-citation-url]').val();
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
                container.find('.pt-citation').html(citation);
            }).trigger('change');
        }; init();
    };

    /**
     * Encapsulates the embed-image panel.
     *
     * The panel is opened by an anchor with data-iiif-url, data-iiif-info-url,
     * and data-title attributes. The size and qualitu options are presented
     * dynamically based on the support declared by the image server in the
     * IIIF information response.
     *
     * @constructor
     */
    var PTEmbedPanel = function() {

        var MIN_IMAGE_SIZE = 200;
        var NUM_BUTTON_SIZE_TIERS = 5;

        var image_url;
        var image_info_url;
        var modal_loaded = false;
        var title;

        var init = function() {
            var embed_modal = $('#pt-custom-image-modal');
            embed_modal.on('show.bs.modal', function(e) {
                // Get the element that was clicked to open the panel.
                var clicked_button = $(e.relatedTarget);
                // Read its relevant data attributes.
                image_url = clicked_button.data('iiif-url');
                image_info_url = clicked_button.data('iiif-info-url');
                title = clicked_button.data('title').trim().replace(/"/g, '&quot;');

                // Load the image's IIIF info.
                $.ajax({
                    dataType: 'json',
                    url: image_info_url,
                    data: null,
                    success: function(data) {
                        renderContents(data);
                    }
                });

                modal_loaded = true;
            });
        }; init();

        var renderContents = function(iiif_info) {
            var container = $('#iiif-download');
            container.empty();
            var full_width = iiif_info['width'];
            var full_height = iiif_info['height'];

            // The 'sizes' array includes sizes only up to 1/2 size. Add the
            // full size to make it available as a download option.
            iiif_info['sizes'].push({
                'width': full_width,
                'height': full_height
            });

            var num_sizes = iiif_info['sizes'].length;

            // find the number of usable sizes (i.e. sizes above
            // MIN_IMAGE_SIZE) in order to calculate button size tiers.
            var num_usable_sizes = 0;
            for (var i = 0; i < num_sizes; i++) {
                var width = iiif_info['sizes'][i]['width'];
                var height = iiif_info['sizes'][i]['height'];
                if (width >= MIN_IMAGE_SIZE && height >= MIN_IMAGE_SIZE) {
                    num_usable_sizes++;
                }
            }

            // Create a button for each size tier from the maximum down to the
            // minimum.
            for (var i = num_sizes - 1, size_i = num_sizes - 1; i >= 0; i--) {
                width = iiif_info['sizes'][i]['width'];
                height = iiif_info['sizes'][i]['height'];

                if (width >= MIN_IMAGE_SIZE && height >= MIN_IMAGE_SIZE) {
                    var size_class = 'pt-size-' +
                        Math.floor(size_i / num_usable_sizes * NUM_BUTTON_SIZE_TIERS);
                    var percent = Math.round(width / full_width * 100);
                    var checked = (size_i === num_sizes - 1) ? 'checked' : '';
                    var active = (size_i === num_sizes - 1) ? 'active' : '';
                    container.append(
                        '<div class="radio btn btn-default ' + size_class + ' ' + active + '">' +
                            '<label>' +
                                '<input type="radio" name="size" value="' + width + ',' + '" ' + checked + '>' +
                                width + '&times;' + height + ' pixels (' + percent + '%)' +
                            '</label>' +
                        '</div><br>');
                    size_i--;
                }
            }

            container.append('<hr>');

            var qualities_div = $('<div class="form-inline"></div>');
            iiif_info['profile'][1]['qualities'].forEach(function (item) {
                // Exclude the "default" quality.
                if (item === 'color' || item === 'gray' || item === 'bitonal') {
                    var checked = '';
                    var container_class = '';
                    if (item === 'color') {
                        checked = 'checked';
                        container_class = 'active';
                    }
                    qualities_div.append(
                        '<div class="radio btn btn-default ' + container_class + '">' +
                            '<label>' +
                                '<input type="radio" name="quality" value="' + item + '" ' + checked + '>' +
                                item.charAt(0).toUpperCase() + item.slice(1) +
                            '</label>' +
                        '</div>');
                }
            });
            container.append(qualities_div);
            container.append('<hr>');

            var formats_div = $('<div class="form-inline"></div>');
            iiif_info['profile'][1]['formats'].forEach(function (item) {
                var checked = '';
                var container_class = '';
                if (item === 'jpg') {
                    checked = 'checked';
                    container_class = 'active';
                }
                var label = item.toUpperCase();
                if (label === 'JPG') {
                    label = 'JPEG';
                } else if (label === 'TIF') {
                    label = 'TIFF';
                }
                formats_div.append(
                    '<div class="radio btn btn-default ' + container_class + '">' +
                        '<label>' +
                            '<input type="radio" name="format" value="' + item + '" ' + checked + '>' +
                            label +
                        '</label>' +
                    '</div>');
            });
            container.append(formats_div);

            var embed_modal = $('#pt-custom-image-modal');

            var displayUrl = function() {
                var size = embed_modal.find('input[name="size"]:checked').val();
                var quality = embed_modal.find('input[name="quality"]:checked').val();
                var format = embed_modal.find('input[name="format"]:checked').val();
                var url = image_url + '/full/' + size + '/0/' + quality + '.' + format;

                $('#pt-preview-link').attr('href', url).show();
                $('#pt-embed-link').val('<img src="' + url + '" alt="' + title + '">');
            };

            $('input[name="size"], input[name="quality"], input[name="format"]').on('click', function () {
                displayUrl();
            });
            displayUrl();

            var radios = embed_modal.find('input[type=radio]');
            radios.on('click', function () {
                radios.each(function () {
                    var radio_container = $(this).parents('div.radio');
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
        $(document).on(PearTree.Events.ITEM_ADDED_TO_FAVORITES, function(event, item) {
            $('.pt-add-to-favorites').hide();
            $('.pt-remove-from-favorites').show();
            updateFavoritesCount();
        });
        $(document).on(PearTree.Events.ITEM_REMOVED_FROM_FAVORITES, function(event, item) {
            $('.pt-remove-from-favorites').hide();
            $('.pt-add-to-favorites').show();
            updateFavoritesCount();
        });
        $('button.pt-add-to-favorites').on('click',
            self.item().addToFavorites);
        $('button.pt-remove-from-favorites').on('click',
            self.item().removeFromFavorites);
        if (self.item().isFavorite()) {
            $('.pt-add-to-favorites').hide();
            $('.pt-remove-from-favorites').show();
        } else {
            $('.pt-remove-from-favorites').hide();
            $('.pt-add-to-favorites').show();
        }

        $('a[href=#pt-download-section]').on('click', function() {
            $('#pt-download').collapse('show');
        });

        // Lazy-load thumbnail images in the download section when it gets
        // expanded.
        $('#pt-download-section').on('shown.bs.collapse', function() {
            PearTree.loadLazyImages();
        });

        // The 3D viewer is initially not loaded. Load it the first time its
        // container div appears.
        $('#pt-3d-viewer-container').on('shown.bs.collapse', function() {
            if (!three_d_viewer_loaded) {
                PearTree.view.threeDViewer.start();
                three_d_viewer_loaded = true;
            }
        });

        var initial_index = $('[name=pt-download-item-index]').val();

        // This acts as both a canvas-index-changed and on-load-complete
        // listener, because UV doesn't have the latter, unless I'm missing
        // something:
        // https://github.com/UniversalViewer/universalviewer/blob/master/src/modules/uv-shared-module/BaseCommands.ts
        $(document).bind('uv.onCanvasIndexChanged', function(event, index) {
            // Select the item in the viewer corresponding to the current URL.
            if (initial_index) {
                console.debug("Initially selected index: " + initial_index);
                index = initial_index;
                // UV doesn't have a "selectCanvasIndex(index)" method as of
                // version 2.0. We can't do this quite yet but there is no
                // event to let us know when it's safe, hence the delay.
                setTimeout(function() {
                    $('#pt-compound-viewer iframe').contents()
                        .find('div#thumb' + index + ' img').trigger('click');
                    initial_index = null;
                }, 500);
            }

            console.debug('Selected canvas index: ' + index);

            // When there are >1 items in the viewer:
            // (N.B. The viewer and the download table will always contain the
            // same items in the same order.)
            var rows = $('#pt-download table tr');
            if (rows.length > 1) {
                // Highlight the corresponding item in the download table.
                // (UV will also fire this on load.)
                rows.removeClass('selected')
                    .filter(':nth-child(' + (index + 1) + ')')
                    .addClass('selected');

                // Update the URL in the location bar.
                var item_id = $('[name=pt-download-item-id]').eq(index).val();
                window.history.replaceState({ id: item_id, index: index }, '',
                    '/items/' + item_id);
            }
        });

        new PTCitationPanel();
        new PTEmbedPanel();
    };

    /**
     * @return PTItem
     */
    this.item = function() {
        var item = new PTItem();
        item.id = $('.pt-add-to-favorites').data('item-id');
        return item;
    };

    var updateFavoritesCount = function() {
        var badge = $('.pt-favorites-count');
        badge.text(PTItem.numFavorites());
    };

};

/**
 * Handles linear items view, a.k.a. results view.
 *
 * @constructor
 */
var PTItemsView = function() {

    var self = this;

    this.init = function() {
        new PearTree.FilterField();
        PearTree.initFacets();

        // submit the sort form on change
        $('select[name="sort"]').on('change', function () {
            $.ajax({
                url: $('[name=pt-current-path]').val(),
                method: 'GET',
                data: $(this).parents('form:first').serialize(),
                dataType: 'script',
                success: function (result) {
                    eval(result);
                }
            });
        });

        attachEventListeners();
    };

    var attachEventListeners = function() {
        $('.pagination a').on('click', function() {
            $('form.pt-filter')[0].scrollIntoView({behavior: "smooth"});
        });
        self.attachFavoritesListeners();
    };

    this.attachFavoritesListeners = function() {
        $(document).on(PearTree.Events.ITEM_ADDED_TO_FAVORITES, function (event, item) {
            $('.pt-results button.pt-remove-from-favorites[data-item-id="' + item.id + '"]').show();
            $('.pt-results button.pt-add-to-favorites[data-item-id="' + item.id + '"]').hide();
            updateFavoritesCount();
        });
        $(document).on(PearTree.Events.ITEM_REMOVED_FROM_FAVORITES, function (event, item) {
            $('.pt-results button.pt-remove-from-favorites[data-item-id="' + item.id + '"]').hide();
            $('.pt-results button.pt-add-to-favorites[data-item-id="' + item.id + '"]').show();
            updateFavoritesCount();
        });
        $('button.pt-add-to-favorites').on('click', function() {
            var item = new PTItem();
            item.id = $(this).data('item-id');
            item.addToFavorites();
        });
        $('button.pt-remove-from-favorites').on('click', function() {
            var item = new PTItem();
            item.id = $(this).data('item-id');
            item.removeFromFavorites();
        });
        $('button.pt-remove-from-favorites, button.pt-add-to-favorites').each(function() {
            var item = new PTItem();
            item.id = $(this).data('item-id');
            if (item.isFavorite()) {
                if ($(this).hasClass('pt-remove-from-favorites')) {
                    $(this).show();
                } else {
                    $(this).hide();
                }
            } else {
                if ($(this).hasClass('pt-add-to-favorites')) {
                    $(this).show();
                } else {
                    $(this).hide();
                }
            }
        });
    };

    var updateFavoritesCount = function() {
        $('.pt-favorites-count').text(PTItem.numFavorites());
    };

};

/**
 * Handles free-form tree view.
 *
 * @constructor
 */
var PTTreeBrowserView = function() {

    this.init = function() {
        initializeTree();
        new PTItemsView().attachFavoritesListeners();
    };

    /**
     * @see https://www.jstree.com/api/#/
     */
    var initializeTree = function() {
        var jstree = $('#jstree');
        if (jstree.length > 0) {
            jstree.jstree({
                core: {
                    multiple: false,
                    data: {
                        url: function (node) {
                            return node.id === '#' ?
                                getCollectionURL() :
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
                var target_id = window.location.hash.substring(1);
                if (target_id) {
                    drillDownToID(target_id);
                }
            }).bind("select_node.jstree", function (e, data) {
                loadItemView(buildAjaxNodeURL(data));

                // Add the selected item ID to the hash portion of the URL.
                console.debug('Navigating to ' + data.node.id);
                window.history.replaceState({id: data.node.id}, '',
                    buildPublicNodeURL(data));
            });

            trigger_root_node();
        }
    };

    /**
     * Drills down through the tree to the leaf node corresponding to the item
     * with the given ID.
     *
     * @param id Item ID.
     */
    var drillDownToID = function(id) {
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
                    if (result.parent) {
                        var parts = result.parent.split('/');
                        var parent = parts[parts.length - 1];
                        console.debug('Parent of ' + id + ' is ' + parent);
                        parents.push(parent);
                        traceLineage(parent, parents, onComplete);
                    } else {
                        onComplete(parents.reverse());
                    }
                },
                error: function(result) {
                    console.error(result);
                }
            });
        };

        traceLineage(id, [], function(parents) {
            drillDown(parents, 0, function() {
                var jstree = $('#jstree');
                jstree.jstree('deselect_all');
                jstree.jstree('select_node', '#' + id);
                window.history.replaceState({id: id}, '', '/items/' + id);
                console.debug('Drill-down complete');
            });
        });
    };

    var buildAjaxNodeURL = function(data) {
        if (data.node.a_attr["name"] === 'root-collection-node') {
            return '/collections/' + data.node.id + '/tree.html?ajax=true';
        }
        return '/items/' + data.node.id + '.html?tree-node-type=' +
            data.node.a_attr["class"];
    };

    var buildPublicNodeURL = function(data) {
        var url;
        if (data.node.a_attr.class.includes('Collection')) {
            url = '/collections/' + data.node.id + '/tree'
        } else {
            url = '/items/' + data.node.id
        }
        return url;
    }

    var tree_node_callback = function(result) {
        //reset flag used by embed.js
        window.embedScriptIncluded = false;
        $('#pt-item-view').html(result);
        $('#pt-item-view ol.breadcrumb').remove();
        $('#pt-item-view .pt-result-navigation').remove();
        $('#pt-item-view .btn-group').removeClass('pull-right');
        $('#pt-item-view .view-dropdown').removeClass('dropdown-menu-right');
        PearTree.init();
        var view = new PTItemView();
        view.init();
    };

    var trigger_root_node = function() {
        loadItemView('/collections/' +
            window.location.pathname.split("/")[2]+'/tree.html?ajax=true');
    };

    var getCollectionURL = function() {
        var ID = window.location.pathname.split("/")[2];
        return '/collections/'+ID+'/items/treedata.json';
    };

    var loadItemView = function(ajax_url) {
        $.ajax({
            url: ajax_url,
            method: 'GET',
            success: function(result) {
                tree_node_callback(result);
            }
        });
    };

};

var ready = function() {
    if ($('body#tree_browser').length) {
        PearTree.view = new PTTreeBrowserView();
        PearTree.view.init();
    } if ($('body#items_index').length) {
        PearTree.view = new PTItemsView();
        PearTree.view.init();
    } else if ($('body#items_show').length) {
        PearTree.view = new PTItemView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
