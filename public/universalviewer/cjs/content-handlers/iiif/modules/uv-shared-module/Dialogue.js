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
exports.Dialogue = void 0;
var $ = require("jquery");
var BaseView_1 = require("./BaseView");
var IIIFEvents_1 = require("../../IIIFEvents");
var Utils_1 = require("../../Utils");
var Dialogue = /** @class */ (function (_super) {
    __extends(Dialogue, _super);
    function Dialogue($element) {
        var _this = _super.call(this, $element, false, false) || this;
        _this.allowClose = true;
        _this.isActive = false;
        _this.isUnopened = true;
        return _this;
    }
    Dialogue.prototype.create = function () {
        var _this = this;
        this.setConfig("dialogue");
        _super.prototype.create.call(this);
        // events.
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.CLOSE_ACTIVE_DIALOGUE, function () {
            if (_this.isActive) {
                if (_this.allowClose) {
                    _this.close();
                }
            }
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.ESCAPE, function () {
            if (_this.isActive) {
                if (_this.allowClose) {
                    _this.close();
                }
            }
        });
        this.$top = $('<div class="top"></div>');
        this.$element.append(this.$top);
        this.$closeButton = $('<button type="button" class="btn btn-default close" tabindex="0">' +
            this.content.close +
            "</button>");
        this.$middle = $('<div class="middle"></div>');
        this.$element.append(this.$middle);
        this.$content = $('<div class="content"></div>');
        this.$middle.append(this.$content);
        this.$buttons = $('<div class="buttons"></div>');
        this.$middle.append(this.$buttons);
        this.$bottom = $('<div class="bottom"></div>');
        this.$element.append(this.$bottom);
        if (this.options.topCloseButtonEnabled) {
            this.$top.append(this.$closeButton);
        }
        else {
            this.$buttons.append(this.$closeButton);
        }
        this.$closeButton.on("click", function (e) {
            e.preventDefault();
            _this.close();
        });
        this.returnFunc = this.close;
    };
    Dialogue.prototype.enableClose = function () {
        this.allowClose = true;
        this.$closeButton.show();
    };
    Dialogue.prototype.disableClose = function () {
        this.allowClose = false;
        this.$closeButton.hide();
    };
    Dialogue.prototype.setDockedPosition = function (position) {
        if (position === void 0) { position = "above"; }
        var top = Math.floor(this.extension.height() - this.$element.outerHeight(true));
        var left = 0;
        var arrowLeft = 0;
        var normalisedPos = 0;
        if (this.$triggerButton) {
            var verticalPadding = 4;
            var horizontalPadding = 2;
            var a = this.$triggerButton.offset().top;
            var b = this.extension.$element.offset()
                .top;
            var d = this.$element.outerHeight(true);
            if (position === "above") {
                var e = a - b - d;
                top = e + verticalPadding;
            }
            else {
                var buttonHeight = this.$triggerButton.outerHeight();
                top = a - b + buttonHeight + verticalPadding;
            }
            var f = this.$triggerButton.offset().left;
            var g = this.extension.$element.offset()
                .left;
            var h = f - g;
            normalisedPos = Utils_1.Maths.normalise(h, 0, this.extension.width());
            left =
                Math.floor(this.extension.width() * normalisedPos -
                    this.$element.width() * normalisedPos) + horizontalPadding;
            arrowLeft = Math.floor(this.$element.width() * normalisedPos);
        }
        if (position === "above") {
            this.$element.removeClass("arrow-top");
            this.$bottom.css("backgroundPosition", arrowLeft + "px 0px");
            this.$bottom.show();
        }
        else {
            this.$element.addClass("arrow-top");
            this.$top.css("backgroundPosition", arrowLeft + "px 0px");
            this.$bottom.hide();
        }
        this.$element.css({
            top: top,
            left: left,
        });
    };
    Dialogue.prototype.open = function (triggerButton) {
        var _this = this;
        this.extensionHost.publish(IIIFEvents_1.IIIFEvents.CLOSE_ACTIVE_DIALOGUE);
        this.$element.attr("aria-hidden", "false");
        this.$element.show();
        if (triggerButton) {
            this.$triggerButton = $(triggerButton);
            this.$bottom.show();
        }
        else {
            this.$bottom.hide();
        }
        this.isActive = true;
        // set the focus to the default button.
        setTimeout(function () {
            var $defaultButton = _this.$element.find(".default");
            if ($defaultButton.length) {
                $defaultButton.focus();
            }
            else {
                // if there's no default button, focus on the first visible input or select element
                var $firstVisibleElement = _this.$element
                    .find("input:visible, select:visible")
                    .first();
                if ($firstVisibleElement.length) {
                    $firstVisibleElement.focus();
                }
                else {
                    // if there's no visible first input, focus on the close button
                    _this.$closeButton.focus();
                }
            }
        }, 1);
        // Add keydown event listener to trap focus within the dialog
        this.$element.on("keydown", function (e) { return _this.handleKeydown(e); });
        this.extensionHost.publish(IIIFEvents_1.IIIFEvents.SHOW_OVERLAY);
        if (this.isUnopened) {
            this.isUnopened = false;
            this.afterFirstOpen();
        }
        this.resize();
    };
    Dialogue.prototype.afterFirstOpen = function () { };
    Dialogue.prototype.close = function () {
        if (!this.isActive)
            return;
        this.$element.attr("aria-hidden", "true");
        this.$element.hide();
        this.isActive = false;
        // Remove the keydown event listener
        this.$element.off("keydown");
        this.extensionHost.publish(this.closeCommand);
        this.extensionHost.publish(IIIFEvents_1.IIIFEvents.HIDE_OVERLAY);
    };
    Dialogue.prototype.resize = function () {
        _super.prototype.resize.call(this);
        this.$element.css({
            top: Math.floor(this.extension.height() / 2 - this.$element.height() / 2),
            left: Math.floor(this.extension.width() / 2 - this.$element.width() / 2),
        });
    };
    Dialogue.prototype.handleKeydown = function (event) {
        if (event.key === "Tab") {
            var focusableSelectors = 'a[href], button, textarea, input[type="text"], input[type="radio"], input[type="checkbox"], select, [tabindex="0"]';
            var focusableElements = this.$element
                .find(focusableSelectors)
                .filter(":visible");
            var firstElement = focusableElements.first()[0];
            var lastElement = focusableElements.last()[0];
            var activeElement = document.activeElement;
            if (event.shiftKey) {
                // Shift + Tab (backwards)
                if (activeElement === firstElement) {
                    event.preventDefault();
                    lastElement.focus();
                }
            }
            else {
                // Tab (forwards)
                if (activeElement === lastElement) {
                    event.preventDefault();
                    firstElement.focus();
                }
            }
        }
    };
    return Dialogue;
}(BaseView_1.BaseView));
exports.Dialogue = Dialogue;
//# sourceMappingURL=Dialogue.js.map