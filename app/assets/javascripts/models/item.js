var FAVORITES_COOKIE_NAME = 'favorites';

/**
 * @constructor
 */
var PTItem = function() {

    var COOKIE_PATH = $('input[name="pt-root-path"]').val();

    this.id = null;

    var self = this;

    this.addToFavorites = function() {
        if (!self.isFavorite()) {
            var favorites = Cookies.get(FAVORITES_COOKIE_NAME);
            var cookie = self.id;
            if (favorites && favorites.length > 0) {
                var parts = favorites.split(',');
                parts.push(self.id);
                cookie = parts.join(',');
            }
            Cookies.set(FAVORITES_COOKIE_NAME, cookie, { path: COOKIE_PATH });
            $(document).trigger(PearTree.Events.ITEM_ADDED_TO_FAVORITES, self);
        }
    };

    this.isFavorite = function() {
        var favorites = Cookies.get(FAVORITES_COOKIE_NAME);
        if (favorites) {
            return favorites.indexOf(self.id) > -1;
        }
        return false;
    };

    this.removeFromFavorites = function() {
        if (self.isFavorite()) {
            var favorites = Cookies.get(FAVORITES_COOKIE_NAME);
            var parts = favorites.split(',');
            parts.splice($.inArray(self.id, parts), 1);
            Cookies.set(FAVORITES_COOKIE_NAME, parts.join(','),
                { path: COOKIE_PATH });
            $(document).trigger(PearTree.Events.ITEM_REMOVED_FROM_FAVORITES,
                self);
        }
    };

};

PTItem.numFavorites = function() {
    var favorites = Cookies.get(FAVORITES_COOKIE_NAME);
    if (favorites && favorites.length > 0) {
        return favorites.split(',').length;
    }
    return 0;
};
