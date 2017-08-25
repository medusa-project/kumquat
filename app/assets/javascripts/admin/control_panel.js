/**
 * A control panel object available in all Control Panel views as
 * PearTree.ControlPanel.
 *
 * @constructor
 */
var PTControlPanel = function() {

    this.init = function() {};

};

var ready = function() {
    PearTree.ControlPanel = new PTControlPanel();
    PearTree.ControlPanel.init();
};

$(document).ready(ready);
$(document).on('page:load', ready);
