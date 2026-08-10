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
exports.ShareDialogue = void 0;
var $ = require("jquery");
var Utils_1 = require("../../Utils");
var IIIFEvents_1 = require("../../IIIFEvents");
var Dialogue_1 = require("../uv-shared-module/Dialogue");
var ShareDialogue = /** @class */ (function (_super) {
    __extends(ShareDialogue, _super);
    function ShareDialogue($element) {
        var _this = _super.call(this, $element) || this;
        _this.copyToClipboardEnabled = true;
        _this.isShareViewVisible = false;
        _this.shareManifestsEnabled = false;
        _this.isEmbedViewVisible = false;
        _this.aspectRatio = 0.75;
        _this.maxWidth = 8000;
        _this.maxHeight = _this.maxWidth * _this.aspectRatio;
        _this.minWidth = 200;
        _this.minHeight = _this.minWidth * _this.aspectRatio;
        return _this;
    }
    ShareDialogue.prototype.create = function () {
        var _this = this;
        var _a;
        this.setConfig("shareDialogue");
        _super.prototype.create.call(this);
        // Accessibility.
        this.$element.attr("role", "region");
        this.$element.attr("aria-label", this.content.share);
        this.openCommand = IIIFEvents_1.IIIFEvents.SHOW_SHARE_DIALOGUE;
        this.closeCommand = IIIFEvents_1.IIIFEvents.HIDE_SHARE_DIALOGUE;
        this.shareManifestsEnabled = this.options.shareManifestsEnabled || false;
        var lastElement;
        this.extensionHost.subscribe(this.openCommand, function (triggerButton) {
            lastElement = triggerButton;
            _this.open(triggerButton);
        });
        this.extensionHost.subscribe(this.closeCommand, function () {
            if (lastElement) {
                lastElement.focus();
            }
            _this.close();
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.SHOW_EMBED_DIALOGUE, function (triggerButton) {
            _this.open(triggerButton);
            if (triggerButton && $(triggerButton).is(".embed.btn")) {
                // after setTimeout in Dialogue super class
                setTimeout(function () {
                    _this.$embedCode.focus();
                }, 2);
            }
        });
        // Title
        var $title = $("<div role=\"heading\" class=\"heading\">".concat(this.content.share, "</div>"));
        this.$content.append($title);
        // Share URL
        this.$urlSection = $("<div class=\"share__section\"><label class=\"share__label\" for=\"embedCode\">".concat(this.content.shareLink, "</label></div>"));
        var shareUrl = this.getShareUrl();
        this.$urlInput = $("<input class=\"copy-input\" id=\"urlInput\" type=\"text\" value=\"".concat(shareUrl, "\" readonly/>"));
        this.$urlInput.focus(function () {
            $(this).select();
        });
        this.$urlSection.append(this.$urlInput);
        this.$content.append(this.$urlSection);
        // Manifest URL
        this.$manifestSection = $("<div class=\"share__section\"><label class=\"share__label\" for=\"manifestCode\">".concat(this.content.iiif, "</label></div>"));
        var iiifUrl = this.extension.getIIIFShareUrl(this.shareManifestsEnabled);
        this.$manifestInput = $("<input class=\"copy-input\" id=\"manifestInput\" type=\"text\" readonly/>").attr("value", iiifUrl);
        this.$manifestInput.focus(function () {
            $(this).select();
        });
        this.$manifestSection.append(this.$manifestInput);
        this.$content.append(this.$manifestSection);
        // Embed IFRAME code
        this.$embedSection = $("<div class=\"share__section\"><label class=\"share__label\" for=\"embedCode\">".concat(this.content.embed, "</label></div>"));
        this.$embedCode = $("<input class=\"copy-input\" id=\"embedCode\" type=\"text\" readonly/>");
        this.$embedCode.focus(function () {
            $(this).select();
        });
        this.$embedSection.append(this.$embedCode);
        this.$content.append(this.$embedSection);
        // Embed size customization
        this.$customSize = $('<div class="customSize"></div>');
        this.$size = $("<label for=\"size\" class=\"size\">".concat(this.content.size, "</label>"));
        this.$customSize.append(this.$size);
        this.$customSizeDropDown = $("<select class=\"embed-size-select\" id=\"size\" aria-label=\"".concat(this.content.size, "\"></select>"));
        this.$customSizeDropDown.append('<option value="small" data-width="560" data-height="420">560 x 420</option>');
        this.$customSizeDropDown.append('<option value="medium" data-width="640" data-height="480">640 x 480</option>');
        this.$customSizeDropDown.append('<option value="large" data-width="800" data-height="600">800 x 600</option>');
        this.$customSizeDropDown.append("<option value=\"custom\">".concat(this.content.customSize, "</option>"));
        this.$customSizeDropDown.change(function () {
            _this.update();
        });
        this.$customSize.append(this.$customSizeDropDown);
        this.$widthInput = $("<input class=\"width\" type=\"text\" maxlength=\"10\" aria-label=\"".concat(this.content.width, "\"/>"));
        this.$widthInput.on("keydown", function (e) {
            return Utils_1.Numbers.numericalInput(e);
        });
        this.$widthInput.change(function () {
            _this.updateHeightRatio();
            _this.update();
        });
        this.$customSize.append(this.$widthInput);
        this.$embedSection.append(this.$customSize);
        // WIDTH x HEIGHT
        this.$x = $('<span class="x">x</span>');
        this.$customSize.append(this.$x);
        this.$heightInput = $("<input class=\"height\" type=\"text\" maxlength=\"10\" aria-label=\"".concat(this.content.height, "\"/>"));
        this.$heightInput.on("keydown", function (e) {
            return Utils_1.Numbers.numericalInput(e);
        });
        this.$heightInput.change(function () {
            _this.updateWidthRatio();
            _this.update();
        });
        this.$customSize.append(this.$heightInput);
        // IIIF Drag and Drop
        var $iiifSection = $('<div class="iiif-section"></div>');
        this.$iiifButton = $("<a class=\"imageBtn iiif\" title=\"".concat(this.content.iiif, "\" target=\"_blank\"></a>")).attr("href", iiifUrl);
        $iiifSection.append(this.$iiifButton);
        this.$content.append($iiifSection);
        // Terms of Use Link
        this.$termsOfUseButton = $("<a href=\"#\">".concat((_a = this.extension.data.config) === null || _a === void 0 ? void 0 : _a.content.termsOfUse, "</a>"));
        $iiifSection.append(this.$termsOfUseButton);
        // Options
        if (this.shareManifestsEnabled) {
            this.$manifestSection.show();
        }
        else {
            this.$manifestSection.hide();
        }
        if (Utils_1.Bools.getBool(this.config.options.embedEnabled, false)) {
            this.$embedSection.show();
        }
        else {
            this.$embedSection.hide();
        }
        // Click Events
        this.onAccessibleClick(this.$termsOfUseButton, function () {
            _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.SHOW_TERMS_OF_USE);
        });
        // Copy buttons
        if (Utils_1.Bools.getBool(this.config.options.copyToClipboardEnabled, true)) {
            this.addCopyButton(this.$urlInput);
            this.addCopyButton(this.$embedCode);
            this.addCopyButton(this.$manifestInput);
        }
        this.$element.hide();
        this.update();
    };
    ShareDialogue.prototype.open = function (triggerButton) {
        _super.prototype.open.call(this, triggerButton);
        this.update();
    };
    ShareDialogue.prototype.getShareUrl = function () {
        return this.extension.getShareUrl();
    };
    ShareDialogue.prototype.isShareAvailable = function () {
        return !!this.getShareUrl();
    };
    ShareDialogue.prototype.addCopyButton = function ($input) {
        var $btn = $("<button class=\"copyBtn\" aria-label=\"".concat(this.content.copyToClipboard, "\">").concat(this.content.copyBtn, "</button>"));
        this.onAccessibleClick($btn, function () {
            Utils_1.Clipboard.copy($input.val());
            $input.focus();
        }, true, true);
        // sleight of hand
        var $copyBtnGroup = $('<div class="copy-group"></div>');
        $copyBtnGroup.append($btn);
        $copyBtnGroup.insertBefore($input);
        $input.insertBefore($btn);
    };
    ShareDialogue.prototype.update = function () {
        if (this.isShareAvailable()) {
            this.$urlSection.show();
        }
        else {
            this.$urlSection.hide();
        }
        var $selected = this.getSelectedSize();
        if ($selected.val() === "custom") {
            this.$widthInput.show();
            this.$x.show();
            this.$heightInput.show();
        }
        else {
            this.$widthInput.hide();
            this.$x.hide();
            this.$heightInput.hide();
            this.currentWidth = Number($selected.data("width"));
            this.currentHeight = Number($selected.data("height"));
            this.$widthInput.val(String(this.currentWidth));
            this.$heightInput.val(String(this.currentHeight));
        }
        this.updateShareOptions();
        this.updateTermsOfUseButton();
    };
    ShareDialogue.prototype.updateShareOptions = function () {
        var shareUrl = this.getShareUrl();
        if (shareUrl) {
            this.$urlInput.val(shareUrl);
        }
    };
    ShareDialogue.prototype.getSelectedSize = function () {
        return this.$customSizeDropDown.find(":selected");
    };
    ShareDialogue.prototype.updateWidthRatio = function () {
        this.currentHeight = Number(this.$heightInput.val());
        if (this.currentHeight < this.minHeight) {
            this.currentHeight = this.minHeight;
            this.$heightInput.val(String(this.currentHeight));
        }
        else if (this.currentHeight > this.maxHeight) {
            this.currentHeight = this.maxHeight;
            this.$heightInput.val(String(this.currentHeight));
        }
        this.currentWidth = Math.floor(this.currentHeight / this.aspectRatio);
        this.$widthInput.val(String(this.currentWidth));
    };
    ShareDialogue.prototype.updateHeightRatio = function () {
        this.currentWidth = Number(this.$widthInput.val());
        if (this.currentWidth < this.minWidth) {
            this.currentWidth = this.minWidth;
            this.$widthInput.val(String(this.currentWidth));
        }
        else if (this.currentWidth > this.maxWidth) {
            this.currentWidth = this.maxWidth;
            this.$widthInput.val(String(this.currentWidth));
        }
        this.currentHeight = Math.floor(this.currentWidth * this.aspectRatio);
        this.$heightInput.val(String(this.currentHeight));
    };
    ShareDialogue.prototype.updateTermsOfUseButton = function () {
        var _a;
        var requiredStatement = this.extension.helper.getRequiredStatement();
        if (Utils_1.Bools.getBool((_a = this.extension.data.config) === null || _a === void 0 ? void 0 : _a.options.termsOfUseEnabled, true) &&
            requiredStatement &&
            requiredStatement.value) {
            this.$termsOfUseButton.show();
        }
        else {
            this.$termsOfUseButton.hide();
        }
    };
    ShareDialogue.prototype.close = function () {
        _super.prototype.close.call(this);
    };
    ShareDialogue.prototype.resize = function () {
        this.setDockedPosition();
    };
    return ShareDialogue;
}(Dialogue_1.Dialogue));
exports.ShareDialogue = ShareDialogue;
//# sourceMappingURL=ShareDialogue.js.map