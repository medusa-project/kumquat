/**
 * Represents show-item view.
 *
 * @constructor
 */
var PTItemView = function() {

    var self = this;

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
