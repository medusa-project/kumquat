/**
 * @constructor
 */
var KQFavoritesView = function() {

    this.init = function() {
        $(document).on(Kumquat.Events.ITEM_REMOVED_FROM_FAVORITES, function(event, item) {
            $('.kq-results button[data-web-id="' + item.web_id + '"]').
                closest('li').fadeOut(function() {
                    var badge = $('.kq-favorites-count');
                    var num_favorites = KQItem.numFavorites();
                    badge.text(num_favorites);
                    if (num_favorites < 1) {
                        $('.kq-no-favorites').show();
                    } else {
                        $('.kq-no-favorites').hide();
                    }
                });
        });
        $('button.kq-remove-from-favorites').on('click', function() {
            var item = new KQItem();
            item.web_id = $(this).data('web-id');
            item.removeFromFavorites();
        });

        if (KQItem.numFavorites() < 1) {
            $('.kq-no-favorites').show();
        } else {
            $('.kq-no-favorites').hide();
        }
        $('.kq-remove-from-favorites').show();
    };

};

var ready = function() {
    if ($('body#favorites').length) {
        Kumquat.view = new KQFavoritesView();
        Kumquat.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
