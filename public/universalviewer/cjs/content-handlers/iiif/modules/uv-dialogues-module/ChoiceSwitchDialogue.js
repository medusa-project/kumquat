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
var IIIFEvents_1 = require("../../IIIFEvents");
var Dialogue_1 = require("../uv-shared-module/Dialogue");
var ChoiceSwitchDialogue = /** @class */ (function (_super) {
    __extends(ChoiceSwitchDialogue, _super);
    function ChoiceSwitchDialogue($element, shell) {
        var _this = _super.call(this, $element) || this;
        _this.shell = shell;
        return _this;
    }
    ChoiceSwitchDialogue.prototype.create = function () {
        var _this = this;
        this.setConfig("choiceSwitchDialogue");
        _super.prototype.create.call(this);
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.SHOW_CHOICE_SWITCH_DIALOGUE, function () {
            _this.open();
        });
        this.$choiceList = $('<div class="choiceList"></div>');
        this.$content.append(this.$choiceList);
        this.$closeButton.hide();
        this.$element.hide();
    };
    ChoiceSwitchDialogue.prototype.open = function () {
        _super.prototype.open.call(this, this.$anchor[0]);
        this.shell.$overlays.css({ background: "none" });
        $(".viewer").addClass("choice-dialogue-open");
        // enable scroll to zoom while the menu is open
        this.shell.$overlays.on("wheel.choiceSwitch", function (e) {
            e.preventDefault();
            var osdCanvas = $(".openseadragon-canvas canvas")[0];
            if (osdCanvas) {
                osdCanvas.dispatchEvent(new WheelEvent("wheel", e.originalEvent));
            }
        });
    };
    ChoiceSwitchDialogue.prototype.close = function () {
        this.shell.$overlays.off("wheel.choiceSwitch");
        this.shell.$overlays.css({ background: "" });
        $(".viewer").removeClass("choice-dialogue-open");
        _super.prototype.close.call(this);
    };
    ChoiceSwitchDialogue.prototype.resize = function () {
        _super.prototype.resize.call(this);
        this.setDockedPosition(this.extension.isMobile() ? "above" : "below");
    };
    return ChoiceSwitchDialogue;
}(Dialogue_1.Dialogue));
exports.ChoiceSwitchDialogue = ChoiceSwitchDialogue;
//# sourceMappingURL=ChoiceSwitchDialogue.js.map