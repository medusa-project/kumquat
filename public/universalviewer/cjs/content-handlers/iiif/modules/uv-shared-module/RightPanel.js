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
exports.RightPanel = void 0;
var Utils_1 = require("../../Utils");
var IIIFEvents_1 = require("../../IIIFEvents");
var BaseExpandPanel_1 = require("./BaseExpandPanel");
var RightPanel = /** @class */ (function (_super) {
    __extends(RightPanel, _super);
    function RightPanel($element) {
        return _super.call(this, $element, false, false) || this;
    }
    RightPanel.prototype.create = function () {
        _super.prototype.create.call(this);
    };
    RightPanel.prototype.init = function () {
        var _this = this;
        _super.prototype.init.call(this);
        var shouldOpenPanel = Utils_1.Bools.getBool(this.extension.getSettings().rightPanelOpen, this.options.panelOpen);
        if (shouldOpenPanel) {
            this.toggle(true);
        }
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.TOGGLE_EXPAND_RIGHT_PANEL, function () {
            if (_this.isFullyExpanded) {
                _this.collapseFull();
            }
            else {
                _this.expandFull();
            }
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.TOGGLE_RIGHT_PANEL, function () {
            _this.toggle();
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.TOGGLE_LEFT_PANEL, function () {
            if (_this.extension.isMetric("sm") && _this.isExpanded) {
                _this.toggle(true);
            }
        });
    };
    RightPanel.prototype.getTargetWidth = function () {
        return this.isExpanded
            ? this.options.panelCollapsedWidth
            : this.options.panelExpandedWidth;
    };
    RightPanel.prototype.getTargetLeft = function () {
        return this.isExpanded
            ? this.$element.parent().width() - this.options.panelCollapsedWidth
            : this.$element.parent().width() - this.options.panelExpandedWidth;
    };
    RightPanel.prototype.toggleFinish = function () {
        var _this = this;
        _super.prototype.toggleFinish.call(this);
        if (this.isExpanded) {
            this.extensionHost.publish(IIIFEvents_1.IIIFEvents.OPEN_RIGHT_PANEL);
        }
        else {
            this.extensionHost.publish(IIIFEvents_1.IIIFEvents.CLOSE_RIGHT_PANEL);
        }
        this.extension.updateSettings({ rightPanelOpen: this.isExpanded });
        // there's a strange rendering issue due to the right panel being transformed by 100% to the right
        // for some reason a 100ms timeout on removing open-finished solves the problem
        // this can't be in the base panel class or the timeout interferes with test running even though it works fine
        setTimeout(function () {
            _this.$element.toggleClass("open-finished");
        }, 100);
    };
    RightPanel.prototype.resize = function () {
        _super.prototype.resize.call(this);
    };
    RightPanel.prototype.toggle = function (autoToggled) {
        if (this.isExpanded) {
            this.$element.parent().removeClass("rightPanelOpen");
        }
        else {
            this.$element.parent().addClass("rightPanelOpen");
        }
        _super.prototype.toggle.call(this, autoToggled);
    };
    RightPanel.prototype.expandFull = function () {
        _super.prototype.expandFull.call(this);
    };
    return RightPanel;
}(BaseExpandPanel_1.BaseExpandPanel));
exports.RightPanel = RightPanel;
//# sourceMappingURL=RightPanel.js.map