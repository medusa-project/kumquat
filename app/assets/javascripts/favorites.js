/**
 * @constructor
 */
var PTFavoritesView = function() {

    this.init = function() {
        $(document).on(PearTree.Events.ITEM_REMOVED_FROM_FAVORITES, function(event, item) {
            $('.pt-results button[data-item-id="' + item.id + '"]').
                closest('li').fadeOut(function() {
                    var badge = $('.pt-favorites-count');
                    var num_favorites = PTItem.numFavorites();
                    badge.text(num_favorites);
                    if (num_favorites < 1) {
                        $('.pt-no-favorites').show();
                    } else {
                        $('.pt-no-favorites').hide();
                    }
                });
        });
        $('button.pt-remove-from-favorites').on('click', function() {
            var item = new PTItem();
            item.id = $(this).data('item-id');
            item.removeFromFavorites();
        });

        if (PTItem.numFavorites() < 1) {
            $('.pt-no-favorites').show();
        } else {
            $('.pt-no-favorites').hide();
        }
        $('.pt-remove-from-favorites').show();
    };

};

var ready = function() {
    if ($('body#favorites').length) {
        PearTree.view = new PTFavoritesView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
