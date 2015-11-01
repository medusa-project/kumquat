/**
 * Represents show-item view.
 *
 * @constructor
 */
var KQItemView = function() {

    var self = this;

    this.init = function() {
        $(document).on(Kumquat.Events.ITEM_ADDED_TO_FAVORITES, function(event, item) {
            $('.kq-add-to-favorites').hide();
            $('.kq-remove-from-favorites').show();
            updateFavoritesCount();
        });
        $(document).on(Kumquat.Events.ITEM_REMOVED_FROM_FAVORITES, function(event, item) {
            $('.kq-remove-from-favorites').hide();
            $('.kq-add-to-favorites').show();
            updateFavoritesCount();
        });
        $('button.kq-add-to-favorites').on('click',
            self.item().addToFavorites);
        $('button.kq-remove-from-favorites').on('click',
            self.item().removeFromFavorites);
        if (self.item().isFavorite()) {
            $('.kq-add-to-favorites').hide();
            $('.kq-remove-from-favorites').show();
        } else {
            $('.kq-remove-from-favorites').hide();
            $('.kq-add-to-favorites').show();
        }
    };

    /**
     * @return KQItem
     */
    this.item = function() {
        var item = new KQItem();
        item.web_id = $('.kq-add-to-favorites').data('web-id');
        return item;
    };

    var updateFavoritesCount = function() {
        var badge = $('.kq-favorites-count');
        badge.text(KQItem.numFavorites());
    };

};

/**
 * Represents items view, a.k.a. results view.
 *
 * @constructor
 */
var KQItemsView = function() {

    this.init = function() {
        $('[name=psap-facet-term]').on('change', function() {
            if ($(this).prop('checked')) {
                window.location = $(this).data('checked-href');
            } else {
                window.location = $(this).data('unchecked-href');
            }
        });

        $(document).on(Kumquat.Events.ITEM_ADDED_TO_FAVORITES, function(event, item) {
            $('.kq-results button.kq-remove-from-favorites[data-web-id="' + item.web_id + '"]').show();
            $('.kq-results button.kq-add-to-favorites[data-web-id="' + item.web_id + '"]').hide();
            updateFavoritesCount();
        });
        $(document).on(Kumquat.Events.ITEM_REMOVED_FROM_FAVORITES, function(event, item) {
            $('.kq-results button.kq-remove-from-favorites[data-web-id="' + item.web_id + '"]').hide();
            $('.kq-results button.kq-add-to-favorites[data-web-id="' + item.web_id + '"]').show();
            updateFavoritesCount();
        });
        $('button.kq-add-to-favorites').on('click', function() {
            var item = new KQItem();
            item.web_id = $(this).data('web-id');
            item.addToFavorites();
        });
        $('button.kq-remove-from-favorites').on('click', function() {
            var item = new KQItem();
            item.web_id = $(this).data('web-id');
            item.removeFromFavorites();
        });
        $('button.kq-remove-from-favorites, button.kq-add-to-favorites').each(function() {
            var item = new KQItem();
            item.web_id = $(this).data('web-id');
            if (item.isFavorite()) {
                if ($(this).hasClass('kq-remove-from-favorites')) {
                    $(this).show();
                } else {
                    $(this).hide();
                }
            } else {
                if ($(this).hasClass('kq-add-to-favorites')) {
                    $(this).show();
                } else {
                    $(this).hide();
                }
            }
        });
    };

    var updateFavoritesCount = function() {
        var badge = $('.kq-favorites-count');
        badge.text(KQItem.numFavorites());
    };

};

var ready = function() {
    if ($('body#items_index').length) {
        Kumquat.view = new KQItemsView();
        Kumquat.view.init();
    } else if ($('body#items_show').length) {
        Kumquat.view = new KQItemView();
        Kumquat.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
