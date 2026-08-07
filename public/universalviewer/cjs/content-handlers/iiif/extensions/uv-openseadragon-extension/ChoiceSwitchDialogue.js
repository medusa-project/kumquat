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
exports.ChoiceSwitchDialogue = void 0;
var ChoiceSwitchDialogue_1 = require("../../modules/uv-dialogues-module/ChoiceSwitchDialogue");
var IIIFEvents_1 = require("../../IIIFEvents");
var Utils_1 = require("../../Utils");
var ChoiceSwitchDialogue = /** @class */ (function (_super) {
    __extends(ChoiceSwitchDialogue, _super);
    function ChoiceSwitchDialogue() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ChoiceSwitchDialogue.prototype.open = function () {
        var _this = this;
        var _a;
        this.$choiceList.empty();
        var extension = this.extension;
        var indices = extension.getPagedIndices();
        var isTwoUp = indices.length > 1;
        // we can use the OSD world as the source of the current view state
        var world = extension.centerPanel.viewer.world;
        indices.forEach(function (canvasIndex) {
            var canvas = extension.helper.getCanvasByIndex(canvasIndex);
            var choices = canvas.getChoices();
            if (!choices.length)
                return;
            var isFirstCanvas = indices.indexOf(canvasIndex) === 0;
            // this is to update the radio buttons to reflect the current state of the OSD world
            // a canvas with "zero" choices has to be counted as one
            var getWorldItemCount = function (canvas) {
                var numChoices = canvas.getChoices().length;
                return numChoices === 0 ? 1 : numChoices;
            };
            var worldOffset = isFirstCanvas
                ? 0
                : getWorldItemCount(extension.helper.getCanvasByIndex(indices[0]));
            var currentChoiceIndex = 0;
            for (var c = 0; c < choices.length; c++) {
                var item = world.getItemAt(worldOffset + c);
                if (item && item.getOpacity() === 1) {
                    currentChoiceIndex = c;
                    break;
                }
            }
            var locale = extension.getLocale();
            var canvasLabel = canvas.getLabel().getValue(locale) ||
                Utils_1.Strings.format(_this.content.canvas, String(canvasIndex + 1));
            if (isTwoUp) {
                var $heading = $("<div class=\"choiceHeading\">".concat(canvasLabel, "</div>"));
                _this.$choiceList.append($heading);
            }
            var $group = $("<div role=\"radiogroup\" aria-label=\"".concat(canvasLabel, "\"></div>"));
            choices.forEach(function (choice, index) {
                var label = choice.getLabel().getValue(locale) ||
                    Utils_1.Strings.format(_this.content.choice, String(index + 1));
                var isActive = index === currentChoiceIndex;
                var $item = $("\n          <label class=\"choiceItem\">\n            <input type=\"radio\" name=\"choice-".concat(canvas.id, "\" value=\"").concat(index, "\" ").concat(isActive ? "checked" : "", " />\n            ").concat(label, "\n          </label>\n        "));
                $item.find("input").on("change", function () {
                    _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.CHOICE_CHANGE, {
                        canvasId: canvas.id,
                        choiceIndex: index,
                    });
                });
                $group.append($item);
            });
            _this.$choiceList.append($group);
        });
        var mobileFooterButton = (_a = extension.mobileFooterPanel) === null || _a === void 0 ? void 0 : _a.$choiceSwitchButton;
        this.$anchor =
            (mobileFooterButton === null || mobileFooterButton === void 0 ? void 0 : mobileFooterButton.is(":visible")) && (mobileFooterButton === null || mobileFooterButton === void 0 ? void 0 : mobileFooterButton.length)
                ? mobileFooterButton
                : extension.centerPanel.$choiceSwitchButton;
        _super.prototype.open.call(this);
    };
    return ChoiceSwitchDialogue;
}(ChoiceSwitchDialogue_1.ChoiceSwitchDialogue));
exports.ChoiceSwitchDialogue = ChoiceSwitchDialogue;
//# sourceMappingURL=ChoiceSwitchDialogue.js.map