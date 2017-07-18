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
     * Encapsulates the download panel.
     *
     * @constructor
     */
    var PTDownloadPanel = function() {

        var init = function() {
            var download_modal = $('#pt-download-modal');

            // When a thumbnail radio is clicked, show its corresponding
            // download options.
            var downloadable_items =
                download_modal.find('input[name="pt-downloadable-item"]');
            if (downloadable_items.length > 0) {
                downloadable_items.on('click', function () {
                    download_modal.find('.pt-download-option, .pt-citation-info').hide();
                    download_modal.find('[data-item-id=' +
                        $(this).data('item-id') + ']').show();
                    download_modal.find('input[name="download-url"][data-item-id="' +
                        $(this).data('item-id') + '"]').trigger('click');
                });
                $('input[name="pt-downloadable-item"]:checked').trigger('click');
            }

            $('#pt-download-button').on('click', function() {
                var source_file = download_modal.find('input[name="download-url"]:checked');
                var url;
                if (source_file.length > 0) {
                    $(this).attr('href', source_file.val());
                }
            });
        }; init();
    };

    /**
     * Encapsulates the embed-image panel.
     *
     * @constructor
     */
    var PTEmbedPanel = function() {

        var MIN_SIZE = 200;
        var NUM_BUTTON_SIZE_TIERS = 6;

        var modal_loaded = false;

        var init = function() {
            var embed_modal = $('#pt-embed-image-modal');
            embed_modal.on('show.bs.modal', function() {
                if (modal_loaded) {
                    return;
                }

                $('input[type=radio][name=pt-embeddable-item]').on('click', function() {
                    loadIiifInfo();
                });
                loadIiifInfo();

                modal_loaded = true;
            });
        }; init();

        var loadIiifInfo = function() {
            // Find the info URL to load; it may be in a radio (for compound
            // objects) or hidden input (for single items).
            var input = $('input[name=pt-embeddable-item]');
            var tmp = input.filter(':checked');
            if (tmp.length > 0) {
                input = tmp;
            }

            $.ajax({
                dataType: 'json',
                url: input.data('iiif-info-url'),
                data: null,
                success: function(data) {
                    renderContents(input.data('iiif-url'), data,
                        input.data('title'));
                }
            });
        };

        var renderContents = function(iiif_url, iiif_info, item_title) {
            var container = $('#iiif-download');
            container.empty();
            var full_width = iiif_info['width'];
            var num_sizes = iiif_info['sizes'].length;

            // find the number of usable sizes in order to calculate button
            // size tiers.
            var num_usable_sizes = 0;
            for (var i = 0; i < num_sizes; i++) {
                var width = iiif_info['sizes'][i]['width'];
                var height = iiif_info['sizes'][i]['height'];
                if (width >= MIN_SIZE && height >= MIN_SIZE) {
                    num_usable_sizes++;
                }
            }

            // Create a button for each size tier up to the maximum.
            for (var i = 0, size_i = 0; i < num_sizes; i++) {
                width = iiif_info['sizes'][i]['width'];
                height = iiif_info['sizes'][i]['height'];

                if (width >= MIN_SIZE && height >= MIN_SIZE) {
                    var size_class = 'pt-size-' +
                        Math.ceil(size_i / num_usable_sizes * NUM_BUTTON_SIZE_TIERS);
                    var percent = Math.round(width / full_width * 100);
                    var checked = (size_i == 0) ? 'checked' : '';
                    var active = (size_i == 0) ? 'active' : '';
                    container.append(
                        '<div class="radio btn btn-default ' + size_class + ' ' + active + '">' +
                            '<label>' +
                                '<input type="radio" name="size" value="' + width + ',' + '" ' + checked + '>' +
                                width + '&times;' + height + ' pixels (' + percent + '%)' +
                            '</label>' +
                        '</div><br>');
                    size_i++;
                }
            }

            var qualities_div = $('<div class="form-inline"></div>');
            iiif_info['profile'][1]['qualities'].forEach(function (item) {
                // Exclude the "default" quality.
                if (item == 'color' || item == 'gray' || item == 'bitonal') {
                    var checked = '';
                    var container_class = '';
                    if (item == 'color') {
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

            var formats_div = $('<div class="form-inline"></div>');
            iiif_info['profile'][1]['formats'].forEach(function (item) {
                var checked = '';
                var container_class = '';
                if (item == 'jpg') {
                    checked = 'checked';
                    container_class = 'active';
                }
                var label = item.toUpperCase();
                if (label == 'JPG') {
                    label = 'JPEG';
                } else if (label == 'TIF') {
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

            var embed_modal = $('#pt-embed-image-modal');

            var displayUrl = function() {
                var size = embed_modal.find('input[name="size"]:checked').val();
                var quality = embed_modal.find('input[name="quality"]:checked').val();
                var format = embed_modal.find('input[name="format"]:checked').val();
                var url = iiif_url + '/full/' + size + '/0/' + quality + '.' + format;
                var title = item_title.trim().replace(/"/g, '&quot;');

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

        // The 3D viewer is initially not loaded. Load it the first time its
        // container div appears.
        $('#pt-3d-viewer-container').on('shown.bs.collapse', function() {
            if (!three_d_viewer_loaded) {
                PearTree.view.threeDViewer.start();
                three_d_viewer_loaded = true;
            }
        });

        new PTCitationPanel();
        new PTDownloadPanel();
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
 * Represents items view, a.k.a. results view.
 *
 * @constructor
 */
var PTItemsView = function() {

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
        $('button.pt-add-to-favorites').on('click', function () {
            var item = new PTItem();
            item.id = $(this).data('item-id');
            item.addToFavorites();
        });
        $('button.pt-remove-from-favorites').on('click', function () {
            var item = new PTItem();
            item.id = $(this).data('item-id');
            item.removeFromFavorites();
        });
        $('button.pt-remove-from-favorites, button.pt-add-to-favorites').each(function () {
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
        if ($('#jstree').length > 0) {
            $('#jstree').jstree({
                core: {
                    data: {
                        url: function (node) {
                            return node.id === '#' ?
                                getCollectionURL() :
                            '/items/' + node.id + '/treedata.json';
                        }
                    }
                }
            }).bind("select_node.jstree", function (e, data) {
                get_item_info(build_node_url(data));
            });
        }

    };

    var updateFavoritesCount = function() {
        var badge = $('.pt-favorites-count');
        badge.text(PTItem.numFavorites());
    };
};


var build_node_url = function(data){
  if (data.node.a_attr["name"]==="root-collection-node"){
      return '/collections/' + data.node.id + '/tree.html?ajax=true';
  }
  return '/items/' + data.node.id + '.html?tree-node-type='+data.node.a_attr["class"];
};
var tree_node_callback = function (result) {
    //reset flag used by embed.js
    window.embedScriptIncluded = false;
        $('#item-info').html(result);
    $('#item-info ol.breadcrumb').remove();
    $('#item-info .pt-result-navigation').remove();
    $('#item-info .btn-group').removeClass('pull-right');
    $('#item-info .view-dropdown').removeClass('dropdown-menu-right');
    PearTree.init();
    var view = new PTItemView();
    view.init();
};
var trigger_root_node = function(){
    get_item_info('/collections/'+window.location.pathname.split("/")[2]+'/tree.html?ajax=true');
};

var get_item_info = function(ajax_url){
    $.ajax({
        url: ajax_url,
        method: 'GET',
        success: function(result) {
            tree_node_callback(result);
        }
    })
};

var get_pagination_link = function(anchor_href){
    var href_array = anchor_href.split("/files");
    return href_array[0]+href_array[1]


};

var getCollectionURL = function() {
    var ID = window.location.pathname.split("/")[2];
    return '/collections/'+ID+'/items/treedata.json';
};

var ready = function() {
    if ($('body#items_index').length) {
        PearTree.view = new PTItemsView();
        PearTree.view.init();
    } else if ($('body#items_show').length) {
        PearTree.view = new PTItemView();
        PearTree.view.init();
    }
    if ($('#jstree').length){
        trigger_root_node();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
