/**
 * @constructor
 */
var PTAdminUsersView = function() {

    this.init = function() {
        $('.popover-dismiss').popover({
            trigger: 'focus'
        });
    };

};

var ready = function() {
    if ($('body#admin_users').length) {
        Application.view = new PTAdminUsersView();
        Application.view.init();
    }
};

$(document).ready(ready);
