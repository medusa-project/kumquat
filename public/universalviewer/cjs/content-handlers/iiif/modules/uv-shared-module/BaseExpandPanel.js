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
exports.BaseExpandPanel = void 0;
var $ = require("jquery");
var Utils_1 = require("../../Utils");
var BaseView_1 = require("./BaseView");
var BaseExpandPanel = /** @class */ (function (_super) {
    __extends(BaseExpandPanel, _super);
    function BaseExpandPanel($element, fitToParentWidth, fitToParentHeight) {
        if (fitToParentWidth === void 0) { fitToParentWidth = false; }
        if (fitToParentHeight === void 0) { fitToParentHeight = true; }
        var _this = _super.call(this, $element, fitToParentWidth, fitToParentHeight) || this;
        _this.isExpanded = false;
        _this.isFullyExpanded = false;
        _this.isUnopened = true;
        _this.autoToggled = false;
        _this.expandFullEnabled = true;
        return _this;
    }
    BaseExpandPanel.prototype.create = function () {
        var _this = this;
        _super.prototype.create.call(this);
        this.$top = $('<div class="top"></div>');
        this.$element.append(this.$top);
        this.$title = $('<h2 class="title"></h2>');
        this.$top.append(this.$title);
        this.$expandFullButton = $('<a class="expandFullButton" tabindex="0"></a>');
        this.$top.append(this.$expandFullButton);
        if (!Utils_1.Bools.getBool(this.config.options.expandFullEnabled, true)) {
            this.$expandFullButton.hide();
        }
        this.$collapseButton = $('<button role="button" class="collapseButton" tabindex="0" aria-expanded="true"></button>');
        this.$collapseButton.prop("title", this.content.collapse);
        this.$collapseButton.attr("aria-label", this.content.collapse);
        this.$top.append(this.$collapseButton);
        this.$closed = $('<div class="closed"></div>');
        this.$element.append(this.$closed);
        this.$expandButton = $('<button role="button" class="expandButton" tabindex="0" aria-expanded="false"></button>');
        this.$expandButton.prop("title", this.content.expand);
        this.$expandButton.attr("aria-label", this.content.expand);
        this.$closed.append(this.$expandButton);
        this.$closedTitle = $('<a class="title"></a>');
        this.$closed.append(this.$closedTitle);
        this.$main = $('<div class="main"></div>');
        this.$element.append(this.$main);
        this.onAccessibleClick(this.$expandButton, function () {
            _this.toggle();
        });
        this.$expandFullButton.on("click", function () {
            _this.expandFull();
        });
        this.$closedTitle.on("click", function () {
            _this.toggle();
        });
        this.$title.on("click", function () {
            if (_this.isFullyExpanded) {
                _this.collapseFull();
            }
            else {
                _this.toggle();
            }
        });
        this.onAccessibleClick(this.$collapseButton, function () {
            if (_this.isFullyExpanded) {
                _this.collapseFull();
            }
            else {
                _this.toggle();
            }
        });
    };
    BaseExpandPanel.prototype.init = function () {
        _super.prototype.init.call(this);
    };
    BaseExpandPanel.prototype.setTitle = function (title) {
        this.$title.text(title);
        this.$closedTitle.text(title);
    };
    BaseExpandPanel.prototype.toggle = function (autoToggled) {
        var _this = this;
        var _a, _b;
        var settings = this.extension.getSettings();
        var isReducedAnimation = settings.reducedAnimation;
        var oldAnimationDuration = document.documentElement.style.getPropertyValue("--uv-animation-duration");
        if (this.options.panelAnimationDuration) {
            document.documentElement.style.setProperty("--uv-animation-duration", "".concat(this.options.panelAnimationDuration, "ms"));
        }
        autoToggled ? (this.autoToggled = true) : (this.autoToggled = false);
        this.$element.toggleClass("open");
        if (this.isExpanded) {
            this.$top.attr("aria-hidden", "true");
            this.$main.attr("aria-hidden", "true");
            this.$closed.attr("aria-hidden", "false");
            this.$collapseButton.attr("aria-expanded", "false");
            this.$expandButton.attr("aria-expanded", "false");
        }
        var timeout = 0;
        if (!isReducedAnimation) {
            timeout =
                ((_b = (_a = this.options.panelAnimationDuration) !== null && _a !== void 0 ? _a : settings.animationDuration) !== null && _b !== void 0 ? _b : 250) + 50;
        }
        setTimeout(function () {
            _this.toggled();
            if (oldAnimationDuration) {
                document.documentElement.style.setProperty("--uv-animation-duration", "".concat(oldAnimationDuration));
            }
        }, timeout);
    };
    BaseExpandPanel.prototype.toggled = function () {
        this.toggleStart();
        this.isExpanded = !this.isExpanded;
        // if expanded show content when animation finished.
        if (this.isExpanded) {
            this.$top.attr("aria-hidden", "false");
            this.$main.attr("aria-hidden", "false");
            this.$closed.attr("aria-hidden", "true");
            this.$collapseButton.attr("aria-expanded", "true");
            this.$expandButton.attr("aria-expanded", "true");
        }
        this.toggleFinish();
        this.isUnopened = false;
    };
    BaseExpandPanel.prototype.expandFull = function () {
        var _this = this;
        var _a, _b;
        var settings = this.extension.getSettings();
        var isReducedAnimation = settings.reducedAnimation;
        var oldAnimationDuration = document.documentElement.style.getPropertyValue("--uv-animation-duration");
        if (this.options.panelAnimationDuration) {
            document.documentElement.style.setProperty("--uv-animation-duration", "".concat(this.options.panelAnimationDuration * 2, "ms"));
        }
        this.expandFullStart();
        var timeout = 0;
        if (!isReducedAnimation) {
            timeout =
                ((_b = (_a = this.options.panelAnimationDuration) !== null && _a !== void 0 ? _a : settings.animationDuration) !== null && _b !== void 0 ? _b : 250) + 50;
            // double it because it's the full expand
            timeout = timeout * 2;
        }
        setTimeout(function () {
            if (!_this.isExpanded) {
                _this.toggled();
            }
            _this.expandFullFinish();
            if (oldAnimationDuration) {
                document.documentElement.style.setProperty("--uv-animation-duration", "".concat(oldAnimationDuration));
            }
        }, timeout);
    };
    BaseExpandPanel.prototype.collapseFull = function () {
        var _this = this;
        var _a, _b;
        var settings = this.extension.getSettings();
        var isReducedAnimation = settings.reducedAnimation;
        var oldAnimationDuration = document.documentElement.style.getPropertyValue("--uv-animation-duration");
        if (this.options.panelAnimationDuration) {
            document.documentElement.style.setProperty("--uv-animation-duration", "".concat(this.options.panelAnimationDuration * 2, "ms"));
        }
        this.collapseFullStart();
        // run a timeout either way, zero just means instant(ish)
        var timeout = 0;
        // if we're not reducing animation then set the correct timeout
        if (!isReducedAnimation) {
            timeout =
                ((_b = (_a = this.options.panelAnimationDuration) !== null && _a !== void 0 ? _a : settings.animationDuration) !== null && _b !== void 0 ? _b : 250) + 50;
            // double duration for full size anims
            timeout = timeout * 2;
        }
        setTimeout(function () {
            _this.collapseFullFinish();
            if (oldAnimationDuration) {
                document.documentElement.style.setProperty("--uv-animation-duration", "".concat(oldAnimationDuration));
            }
        }, timeout);
    };
    BaseExpandPanel.prototype.getTargetWidth = function () {
        return 0;
    };
    BaseExpandPanel.prototype.getTargetLeft = function () {
        return 0;
    };
    BaseExpandPanel.prototype.getFullTargetWidth = function () {
        return 0;
    };
    BaseExpandPanel.prototype.getFullTargetLeft = function () {
        return 0;
    };
    BaseExpandPanel.prototype.toggleStart = function () { };
    BaseExpandPanel.prototype.toggleFinish = function () {
        if (this.autoToggled) {
            return;
        }
        if (this.isExpanded) {
            this.focusCollapseButton();
        }
        else {
            this.focusExpandButton();
        }
    };
    BaseExpandPanel.prototype.expandFullStart = function () { };
    BaseExpandPanel.prototype.expandFullFinish = function () {
        this.isFullyExpanded = true;
        this.$expandFullButton.hide();
    };
    BaseExpandPanel.prototype.collapseFullStart = function () { };
    BaseExpandPanel.prototype.collapseFullFinish = function () {
        this.isFullyExpanded = false;
        if (this.expandFullEnabled) {
            this.$expandFullButton.show();
        }
        this.focusExpandFullButton();
    };
    BaseExpandPanel.prototype.focusExpandButton = function () {
        var _this = this;
        setTimeout(function () {
            _this.$expandButton.focus();
        }, 1);
    };
    BaseExpandPanel.prototype.focusExpandFullButton = function () {
        var _this = this;
        setTimeout(function () {
            _this.$expandFullButton.focus();
        }, 1);
    };
    BaseExpandPanel.prototype.focusCollapseButton = function () {
        var _this = this;
        setTimeout(function () {
            _this.$collapseButton.focus();
        }, 1);
    };
    BaseExpandPanel.prototype.resize = function () {
        _super.prototype.resize.call(this);
        this.$main.height(this.$element.height() - this.$top.outerHeight(true));
    };
    return BaseExpandPanel;
}(BaseView_1.BaseView));
exports.BaseExpandPanel = BaseExpandPanel;
//# sourceMappingURL=BaseExpandPanel.js.map