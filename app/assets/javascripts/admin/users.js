/**
 * @constructor
 */
const DLAdminUsersView = function() {

    this.init = function() {
        $('.popover-dismiss').popover({
            trigger: 'focus'
        });
    };

};

$(document).ready(function() {
    if ($('body#admin_users').length) {
        Application.view = new DLAdminUsersView();
        Application.view.init();
    }
});
