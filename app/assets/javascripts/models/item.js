var FAVORITES_COOKIE_NAME = 'favorites';

/**
 * @constructor
 */
var KQItem = function() {

    var COOKIE_PATH = $('input[name="pt-root-path"]').val();

    this.web_id = null;

    var self = this;

    this.addToFavorites = function() {
        if (!self.isFavorite()) {
            var favorites = $.cookie(FAVORITES_COOKIE_NAME);
            var cookie = self.web_id;
            if (favorites && favorites.length > 0) {
                var parts = favorites.split(',');
                parts.push(self.web_id);
                cookie = parts.join(',');
            }
            $.cookie(FAVORITES_COOKIE_NAME, cookie, { path: COOKIE_PATH });
            $(document).trigger(PearTree.Events.ITEM_ADDED_TO_FAVORITES, self);
        }
    };

    this.isFavorite = function() {
        var favorites = $.cookie(FAVORITES_COOKIE_NAME);
        if (favorites) {
            return favorites.indexOf(self.web_id) > -1;
        }
        return false;
    };

    this.removeFromFavorites = function() {
        if (self.isFavorite()) {
            var favorites = $.cookie(FAVORITES_COOKIE_NAME);
            var parts = favorites.split(',');
            parts.splice($.inArray(self.web_id, parts), 1);
            $.cookie(FAVORITES_COOKIE_NAME, parts.join(','),
                { path: COOKIE_PATH });
            $(document).trigger(PearTree.Events.ITEM_REMOVED_FROM_FAVORITES,
                self);
        }
    };

};

KQItem.numFavorites = function() {
    var favorites = $.cookie(FAVORITES_COOKIE_NAME);
    if (favorites && favorites.length > 0) {
        return favorites.split(',').length;
    }
    return 0;
};
