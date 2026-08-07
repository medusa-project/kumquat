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
exports.FooterPanel = void 0;
var $ = require("jquery");
var FooterPanel_1 = require("../uv-shared-module/FooterPanel");
var Events_1 = require("../../extensions/uv-openseadragon-extension/Events");
var IIIFEvents_1 = require("../../IIIFEvents");
var Events_2 = require("../../../../Events");
var FooterPanel = /** @class */ (function (_super) {
    __extends(FooterPanel, _super);
    function FooterPanel($element) {
        return _super.call(this, $element) || this;
    }
    FooterPanel.prototype.create = function () {
        var _this = this;
        this.setConfig("mobileFooterPanel");
        _super.prototype.create.call(this);
        this.extensionHost.subscribe(Events_2.Events.LOAD, function () {
            _this.updateChoiceSwitchVisibility();
        });
        // this.$spacer = $('<div class="spacer"></div>');
        // this.$options.prepend(this.$spacer);
        this.$rotateButton = $("\n            <button class=\"btn imageBtn rotate\" title=\"".concat(this.content.rotateRight, "\">\n                <i class=\"uv-icon-rotate\" aria-hidden=\"true\"></i>").concat(this.content.rotateRight, "\n            </button>\n        "));
        this.$mainOptions.prepend(this.$rotateButton);
        this.$zoomOutButton = $("\n            <button class=\"btn imageBtn zoomOut\" title=\"".concat(this.content.zoomOut, "\">\n                <i class=\"uv-icon-zoom-out\" aria-hidden=\"true\"></i>").concat(this.content.zoomOut, "\n            </button>\n        "));
        this.$mainOptions.prepend(this.$zoomOutButton);
        this.$zoomInButton = $("\n            <button class=\"btn imageBtn zoomIn\" title=\"".concat(this.content.zoomIn, "\">\n                <i class=\"uv-icon-zoom-in\" aria-hidden=\"true\"></i>").concat(this.content.zoomIn, "\n            </button>\n        "));
        this.$mainOptions.prepend(this.$zoomInButton);
        this.$helpButton = $("\n      <a class=\"btn imageBtn help\" tabindex=\"0\" title=\"".concat(this.content.help, "\" role=\"button\">\n        <i class=\"uv-icon-help\" aria-hidden=\"true\"></i>\n      </a>\n    "));
        this.$options.prepend(this.$helpButton);
        this.$choiceSwitchButton = $("\n      <button class=\"btn imageBtn choiceSwitch\" title=\"".concat(this.content.layers, "\">\n        <i class=\"uv-icon-layers\" aria-hidden=\"true\"></i>").concat(this.content.layers, "\n      </button>\n    "));
        this.$mainOptions.append(this.$choiceSwitchButton);
        if (this.options.helpEnabled && this.options.helpUrl) {
            this.$helpButton.show();
        }
        else {
            this.$helpButton.hide();
        }
        this.$helpButton.onPressed(function () {
            window.open(_this.options.helpUrl);
        });
        this.$zoomInButton.onPressed(function () {
            _this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.ZOOM_IN);
        });
        this.$zoomOutButton.onPressed(function () {
            _this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.ZOOM_OUT);
        });
        this.$rotateButton.onPressed(function () {
            _this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.ROTATE);
        });
        this.$choiceSwitchButton.onPressed(function () {
            _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.SHOW_CHOICE_SWITCH_DIALOGUE);
        });
    };
    FooterPanel.prototype.updateChoiceSwitchVisibility = function () {
        var _this = this;
        var indices = this.extension.getPagedIndices();
        var hasChoices = indices.some(function (index) {
            var canvas = _this.extension.helper.getCanvasByIndex(index);
            return canvas.getChoices().length > 0;
        });
        this.$choiceSwitchButton.css("visibility", hasChoices ? "visible" : "hidden");
    };
    FooterPanel.prototype.resize = function () {
        var _this = this;
        _super.prototype.resize.call(this);
        setTimeout(function () {
            _this.$options.css("left", Math.floor(_this.$element.width() / 2 - _this.$options.width() / 2));
        }, 1);
    };
    return FooterPanel;
}(FooterPanel_1.FooterPanel));
exports.FooterPanel = FooterPanel;
//# sourceMappingURL=MobileFooter.js.map