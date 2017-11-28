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
                        $('#pt-download-menu').hide();
                    } else {
                        $('.pt-no-favorites').hide();
                        $('#pt-download-menu').show();
                    }
                });
        });

        if (PTItem.numFavorites() < 1) {
            $('.pt-no-favorites').show();
            $('#pt-download-menu').hide();
        } else {
            $('.pt-no-favorites').hide();
            $('#pt-download-menu').show();
        }
        $('.pt-remove-from-favorites').show();

        // When the download-zip button is clicked, check if any items are,
        // selected, and if so, append them to an "ids" key in the URL query.
        $('#pt-download-zip-modal a.btn').on('click', function() {
            var ids = []
            $('[name="pt-selected-items[]"]:checked').each(function() {
                ids.push($(this).val());
            });
            if (ids.length) {
                $(this).attr('href', $(this).attr('href') + '&ids=' + ids.join(','));
            }
        });

        attachEventListeners();
    };

    var attachEventListeners = function() {
        $('button.pt-remove-from-favorites').on('click', function() {
            var item = new PTItem();
            item.id = $(this).data('item-id');
            item.removeFromFavorites();
        });

        $('.pagination a').on('click', function() {
            $('.pt-results')[0].scrollIntoView({behavior: "smooth"});
        });
    };

};

var ready = function() {
    if ($('body#favorites').length) {
        PearTree.view = new PTFavoritesView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
