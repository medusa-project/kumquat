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
var AdjustImageDialogue_1 = require("../../modules/uv-dialogues-module/AdjustImageDialogue");
var AdjustImageDialogue = /** @class */ (function (_super) {
    __extends(AdjustImageDialogue, _super);
    function AdjustImageDialogue($element, shell) {
        return _super.call(this, $element, shell) || this;
    }
    AdjustImageDialogue.prototype.create = function () {
        this.setConfig("shareDialogue");
        _super.prototype.create.call(this);
    };
    AdjustImageDialogue.prototype.resize = function () {
        _super.prototype.resize.call(this);
    };
    return AdjustImageDialogue;
}(AdjustImageDialogue_1.AdjustImageDialogue));
exports.AdjustImageDialogue = AdjustImageDialogue;
//# sourceMappingURL=AdjustImageDialogue.js.map