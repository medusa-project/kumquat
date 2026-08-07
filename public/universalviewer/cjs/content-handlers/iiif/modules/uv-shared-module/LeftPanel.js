"use strict";
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.LeftPanel = void 0;
var Utils_1 = require("../../Utils");
var IIIFEvents_1 = require("../../IIIFEvents");
var BaseExpandPanel_1 = require("./BaseExpandPanel");
var LeftPanel = /** @class */ (function (_super) {
    __extends(LeftPanel, _super);
    function LeftPanel($element) {
        return _super.call(this, $element, false, false) || this;
    }
    LeftPanel.prototype.create = function () {
        var _this = this;
        _super.prototype.create.call(this);
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.TOGGLE_EXPAND_LEFT_PANEL, function () {
            if (_this.isFullyExpanded) {
                _this.collapseFull();
            }
            else {
                _this.expandFull();
            }
        });
    };
    LeftPanel.prototype.init = function () {
        var _this = this;
        _super.prototype.init.call(this);
        var shouldOpenPanel = Utils_1.Bools.getBool(this.extension.getSettings().leftPanelOpen, this.options.panelOpen && !this.extension.isMetric("sm"));
        if (shouldOpenPanel) {
            this.toggle(true);
        }
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.TOGGLE_LEFT_PANEL, function () {
            _this.toggle();
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.TOGGLE_RIGHT_PANEL, function () {
            if (_this.extension.isMetric("sm") && _this.isExpanded) {
                _this.toggle(true);
            }
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.THUMB_SELECTED, function () {
            if (_this.extension.isMetric("sm")) {
                _this.toggle();
            }
        });
    };
    LeftPanel.prototype.getTargetWidth = function () {
        if (this.isFullyExpanded || !this.isExpanded) {
            return this.options.panelExpandedWidth;
        }
        else {
            return this.options.panelCollapsedWidth;
        }
    };
    LeftPanel.prototype.getFullTargetWidth = function () {
        return this.$element.parent().width();
    };
    LeftPanel.prototype.toggleFinish = function () {
        _super.prototype.toggleFinish.call(this);
        if (this.isExpanded) {
            this.extensionHost.publish(IIIFEvents_1.IIIFEvents.OPEN_LEFT_PANEL);
        }
        else {
            this.extensionHost.publish(IIIFEvents_1.IIIFEvents.CLOSE_LEFT_PANEL);
        }
        this.extension.updateSettings({ leftPanelOpen: this.isExpanded });
        this.$element.toggleClass("open-finished");
    };
    LeftPanel.prototype.resize = function () {
        _super.prototype.resize.call(this);
    };
    LeftPanel.prototype.toggle = function (autoToggled) {
        if (this.isExpanded) {
            this.$element.parent().removeClass("leftPanelOpen");
        }
        else {
            this.$element.parent().addClass("leftPanelOpen");
        }
        _super.prototype.toggle.call(this, autoToggled);
    };
    LeftPanel.prototype.expandFull = function () {
        this.$element.parent().addClass("leftPanelOpenFull");
        this.$element.addClass("open");
        _super.prototype.expandFull.call(this);
    };
    LeftPanel.prototype.collapseFull = function () {
        this.$element.parent().removeClass("leftPanelOpenFull");
        // Collapsing the fully open left panel doesn't actually close it,
        // it puts it back to the normal open state.
        // However, if the panel was closed when expandFull was triggered
        // the .mainPanel (parent of .leftPanel) won't have the class leftPanelOpen
        // which is required when the panel is in a normal open state (for the css grid to be set correctly).
        // So we check for this and add the class if necessary.
        if (!this.$element.parent().hasClass("leftPanelOpen")) {
            this.$element.parent().addClass("leftPanelOpen");
        }
        _super.prototype.collapseFull.call(this);
    };
    return LeftPanel;
}(BaseExpandPanel_1.BaseExpandPanel));
exports.LeftPanel = LeftPanel;
//# sourceMappingURL=LeftPanel.js.map