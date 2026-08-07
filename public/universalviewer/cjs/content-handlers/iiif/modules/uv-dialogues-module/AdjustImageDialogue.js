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
exports.AdjustImageDialogue = void 0;
var $ = require("jquery");
var IIIFEvents_1 = require("../../IIIFEvents");
var Dialogue_1 = require("../uv-shared-module/Dialogue");
var AdjustImageDialogue = /** @class */ (function (_super) {
    __extends(AdjustImageDialogue, _super);
    function AdjustImageDialogue($element, shell) {
        var _this = _super.call(this, $element) || this;
        _this.contrastPercent = 100;
        _this.brightnessPercent = 100;
        _this.saturationPercent = 100;
        _this.rememberSettings = false;
        _this.shell = shell;
        return _this;
    }
    AdjustImageDialogue.prototype.create = function () {
        var _this = this;
        var _a;
        this.setConfig("adjustImageDialogue");
        _super.prototype.create.call(this);
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.SHOW_ADJUSTIMAGE_DIALOGUE, function () {
            _this.open();
        });
        this.$title = $("<div role=\"heading\" class=\"heading\"></div>");
        this.$content.append(this.$title);
        this.$contrastLabel = $('<label for="contrastInput">' + this.content.contrast + "</label>");
        this.$contrastInput = $('<input id="contrastInput" type="range" min="1" max="200" step="1"></input>');
        this.$content.append(this.$contrastLabel);
        this.$content.append(this.$contrastInput);
        this.$brightnessLabel = $('<label for="brightnessInput">' + this.content.brightness + "</label>");
        this.$brightnessInput = $('<input id="brightnessInput" type="range" min="1" max="200" step="1"></input>');
        this.$content.append(this.$brightnessLabel);
        this.$content.append(this.$brightnessInput);
        this.$saturationLabel = $('<label for="saturationInput">' + this.content.saturation + "</label>");
        this.$saturationInput = $('<input id="saturationInput" type="range" min="1" max="200" step="1"></input>');
        this.$content.append(this.$saturationLabel);
        this.$content.append(this.$saturationInput);
        this.$title.text(this.content.title);
        if ((_a = this.extension.data.config) === null || _a === void 0 ? void 0 : _a.options.saveUserSettings) {
            this.$rememberContainer = $('<div class="rememberContainer"></div>');
            this.$rememberCheckbox = $('<input type="checkbox" id="rememberSettings" />');
            this.$rememberLabel = $('<label for="rememberSettings">' + this.content.remember + "</label>");
            this.$rememberContainer.append(this.$rememberCheckbox);
            this.$rememberContainer.append(this.$rememberLabel);
            this.$content.append(this.$rememberContainer);
            this.$rememberCheckbox.on("input", function (e) {
                _this.rememberSettings = _this.$rememberCheckbox.prop("checked");
            });
        }
        this.$contrastInput.on("input", function (e) {
            _this.contrastPercent = Number($(e.target).val());
            _this.filter();
        });
        this.$brightnessInput.on("input", function (e) {
            _this.brightnessPercent = Number($(e.target).val());
            _this.filter();
        });
        this.$saturationInput.on("input", function (e) {
            _this.saturationPercent = Number($(e.target).val());
            _this.filter();
        });
        this.$resetButton = this.$buttons.find(".close").clone();
        this.$resetButton.prop("title", this.content.reset);
        this.$resetButton.text(this.content.reset);
        this.$resetButton.onPressed(function () {
            _this.contrastPercent = 100;
            _this.brightnessPercent = 100;
            _this.saturationPercent = 100;
            _this.$contrastInput.val(_this.contrastPercent);
            _this.$brightnessInput.val(_this.brightnessPercent);
            _this.$saturationInput.val(_this.saturationPercent);
            var canvas = (_this.extension.centerPanel.$canvas[0]
                .children[0]);
            canvas.style.filter = "none";
        });
        this.$resetButton.insertBefore(this.$buttons.find(".close"));
        this.$element.hide();
    };
    AdjustImageDialogue.prototype.filter = function () {
        var canvas = (this.extension.centerPanel.$canvas[0]
            .children[0]);
        canvas.style.filter = "contrast(".concat(this.contrastPercent, "%) brightness(").concat(this.brightnessPercent, "%) saturate(").concat(this.saturationPercent, "%)");
    };
    AdjustImageDialogue.prototype.open = function () {
        var _a;
        // Check if we have saved setings
        var settings = this.extension.getSettings();
        if (settings.rememberSettings) {
            this.contrastPercent = Number(settings.contrastPercent);
            this.brightnessPercent = Number(settings.brightnessPercent);
            this.saturationPercent = Number(settings.saturationPercent);
            this.$contrastInput.val(this.contrastPercent);
            this.$brightnessInput.val(this.brightnessPercent);
            this.$saturationInput.val(this.saturationPercent);
            if ((_a = this.extension.data.config) === null || _a === void 0 ? void 0 : _a.options.saveUserSettings) {
                this.$rememberCheckbox.prop("checked", settings.rememberSettings);
                this.rememberSettings = settings.rememberSettings;
            }
        }
        _super.prototype.open.call(this);
        this.shell.$overlays.css("background", "none");
    };
    AdjustImageDialogue.prototype.close = function () {
        // Check if we should save settings
        if (this.rememberSettings) {
            this.extension.updateSettings({
                rememberSettings: this.rememberSettings,
            });
            this.extension.updateSettings({ contrastPercent: this.contrastPercent });
            this.extension.updateSettings({
                brightnessPercent: this.brightnessPercent,
            });
            this.extension.updateSettings({
                saturationPercent: this.saturationPercent,
            });
        }
        else {
            this.extension.updateSettings({ rememberSettings: false });
            this.extension.updateSettings({ contrastPercent: 100 });
            this.extension.updateSettings({ brightnessPercent: 100 });
            this.extension.updateSettings({ saturationPercent: 100 });
        }
        this.shell.$overlays.css("background", "");
        _super.prototype.close.call(this);
        // put focus back on the button when the dialogue is closed
        (this.extension).centerPanel.$adjustImageButton.focus();
    };
    AdjustImageDialogue.prototype.resize = function () {
        _super.prototype.resize.call(this);
        this.$element.css({ top: 16, left: 16 });
    };
    return AdjustImageDialogue;
}(Dialogue_1.Dialogue));
exports.AdjustImageDialogue = AdjustImageDialogue;
//# sourceMappingURL=AdjustImageDialogue.js.map