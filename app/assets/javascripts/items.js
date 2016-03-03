/**
 * Represents show-item view.
 *
 * @constructor
 */
var PTItemView = function() {

    var self = this;
    var download_modal_loaded = false;

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

        $('select.pt-page-select').on('change', function() {
            window.location = $(this).val();
        });

        $(window).on('resize', function() {
            var viewer = $('#pt-image-viewer');
            if (!viewer.hasClass('fullpage')) {
                viewer.height($(window).height() * 0.75);
            }
        }).trigger('resize');

        // When the download modal is shown, populate the IIIF download form.
        var download_modal = $('#pt-download-modal');
        download_modal.on('show.bs.modal', function() {
            if (download_modal_loaded) {
                return;
            }
            var container = $('#iiif-download');
            if (container != null) { // will be null for non-images
                $.ajax({
                    dataType: 'json',
                    url: $('input[name="iiif-download-info-json-url"]').val(),
                    data: null,
                    success: function(data) {
                        container.before('<h4>Reduced Image</h4>');

                        var NUM_SIZE_TIERS = 6;
                        var MIN_SIZE = 400;
                        var full_width = data['width'];
                        var full_height = data['height'];
                        var num_sizes = data['sizes'].length;

                        // find the number of usable sizes in order to calculate
                        // button size tiers
                        var num_usable_sizes = 0;
                        for (var i = 0; i < num_sizes; i++) {
                            var width = data['sizes'][i]['width'];
                            var height = data['sizes'][i]['height'];
                            if (width >= MIN_SIZE && height >= MIN_SIZE) { // arbitrary cutoff
                                num_usable_sizes++;
                            }
                        }

                        for (var i = 0, size_i = 0; i < num_sizes; i++) {
                            var width = data['sizes'][i]['width'];
                            var height = data['sizes'][i]['height'];

                            if (width >= MIN_SIZE && height >= MIN_SIZE) { // arbitrary cutoff
                                var size_class = 'pt-size-' +
                                    Math.ceil(size_i / num_usable_sizes * NUM_SIZE_TIERS);
                                var percent = Math.round(width / full_width * 100);
                                container.append(
                                    '<div class="radio btn btn-default ' + size_class + '">' +
                                        '<label>' +
                                            '<input type="radio" name="size" value="' + width + ',' + height + '">' +
                                            width + '&times;' + height + ' pixels (' + percent + '%)' +
                                        '</label>' +
                                    '</div>');
                                size_i++;
                            }
                        }

                        var qualities_div = $('<div class="form-inline"></div>');
                        data['profile'][1]['qualities'].forEach(function(item) {
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
                        data['profile'][1]['formats'].forEach(function(item) {
                            var checked = '';
                            var container_class = '';
                            if (item == 'jpg') {
                                checked = 'checked';
                                container_class = 'active';
                            }
                            formats_div.append(
                                    '<div class="radio btn btn-default ' + container_class + '">' +
                                        '<label>' +
                                            '<input type="radio" name="format" value="' + item + '" ' + checked + '>' +
                                            item.toUpperCase() +
                                        '</label>' +
                                    '</div>');
                        });
                        container.append(formats_div);

                        $('input[name="download-url"]').on('click', function() {
                            $('input[name="size"]:checked').prop('checked', false);
                            //$('input[name="quality"]:checked').attr('checked', false);
                            //$('input[name="format"]:checked').attr('checked', false);
                        });

                        $('input[name="size"], input[name="quality"], input[name="format"]').on('click', function() {
                            $('input[name="download-url"]').prop('checked', false);
                        });

                        var radios = download_modal.find('input[type=radio]');
                        radios.on('change', function() {
                            radios.each(function() {
                                var radio_container = $(this).parents('div.radio');
                                if ($(this).is(':checked')) {
                                    radio_container.addClass('active');
                                } else {
                                    radio_container.removeClass('active');
                                }
                            });
                        });
                    }
                });
            }
            download_modal_loaded = true;
        });

        $('#pt-download').on('click', function() {
            var form = $(this).parent().prev().find('form');
            var source_file = form.find('input[name="download-url"]:checked');
            var url;
            if (source_file.length > 0) {
                url = source_file.val();
            } else {
                var size = form.find('input[name="size"]:checked').val();
                var quality = form.find('input[name="quality"]:checked').val();
                var format = form.find('input[name="format"]:checked').val();
                url = $('input[name="iiif-download-url"]').val() +
                    '/full/' + size + '/0/' + quality + '.' + format;
            }

            if (url != null) {
                window.open(url, '_blank');
                //download_modal.modal('hide');
            }
        });
    };

    /**
     * @return PTItem
     */
    this.item = function() {
        var item = new PTItem();
        item.web_id = $('.pt-add-to-favorites').data('web-id');
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
        $('[name=pt-facet-term]').on('change', function() {
            if ($(this).prop('checked')) {
                window.location = $(this).data('checked-href');
            } else {
                window.location = $(this).data('unchecked-href');
            }
        });

        // submit the sort form on change
        $('select[name="sort"]').on('change', function() {
            $(this).parents('form').submit();
        });

        $(document).on(PearTree.Events.ITEM_ADDED_TO_FAVORITES, function(event, item) {
            $('.pt-results button.pt-remove-from-favorites[data-web-id="' + item.web_id + '"]').show();
            $('.pt-results button.pt-add-to-favorites[data-web-id="' + item.web_id + '"]').hide();
            updateFavoritesCount();
        });
        $(document).on(PearTree.Events.ITEM_REMOVED_FROM_FAVORITES, function(event, item) {
            $('.pt-results button.pt-remove-from-favorites[data-web-id="' + item.web_id + '"]').hide();
            $('.pt-results button.pt-add-to-favorites[data-web-id="' + item.web_id + '"]').show();
            updateFavoritesCount();
        });
        $('button.pt-add-to-favorites').on('click', function() {
            var item = new PTItem();
            item.web_id = $(this).data('web-id');
            item.addToFavorites();
        });
        $('button.pt-remove-from-favorites').on('click', function() {
            var item = new PTItem();
            item.web_id = $(this).data('web-id');
            item.removeFromFavorites();
        });
        $('button.pt-remove-from-favorites, button.pt-add-to-favorites').each(function() {
            var item = new PTItem();
            item.web_id = $(this).data('web-id');
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
        var badge = $('.pt-favorites-count');
        badge.text(PTItem.numFavorites());
    };

};

var ready = function() {
    if ($('body#items_index').length) {
        PearTree.view = new PTItemsView();
        PearTree.view.init();
    } else if ($('body#items_show').length) {
        PearTree.view = new PTItemView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
