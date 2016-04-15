/**
 * Represents collection list view.
 *
 * @constructor
 */
var PTCollectionsView = function() {

    this.init = function() {
        var SCROLL_OFFSET = 60;
        $('body').scrollspy({
            target: '#pt-letter-links',
            offset: SCROLL_OFFSET
        });
        $('#pt-letter-links').affix({
            offset: { top: 505 }
        });
        PearTree.smoothAnchorScroll(SCROLL_OFFSET);
    };

};

var ready = function() {
    if ($('body#collections_index').length) {
        PearTree.view = new PTCollectionsView();
        PearTree.view.init();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
