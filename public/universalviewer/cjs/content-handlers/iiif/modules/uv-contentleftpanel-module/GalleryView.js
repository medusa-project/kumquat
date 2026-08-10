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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GalleryView = void 0;
var IIIFEvents_1 = require("../../IIIFEvents");
var BaseView_1 = require("../uv-shared-module/BaseView");
var GalleryComponent_1 = require("../uv-shared-module/GalleryComponent");
var jquery_1 = __importDefault(require("jquery"));
var GalleryView = /** @class */ (function (_super) {
    __extends(GalleryView, _super);
    function GalleryView($element, fitToParentWidth, fitToParentHeight) {
        if (fitToParentWidth === void 0) { fitToParentWidth = true; }
        if (fitToParentHeight === void 0) { fitToParentHeight = true; }
        var _this = _super.call(this, $element, fitToParentWidth, fitToParentHeight) || this;
        _this.isOpen = false;
        return _this;
    }
    GalleryView.prototype.create = function () {
        this.setConfig("contentLeftPanel");
        _super.prototype.create.call(this);
        this.$gallery = (0, jquery_1.default)('<div class="iiif-gallery-component"></div>');
        this.$element.append(this.$gallery);
    };
    GalleryView.prototype.setup = function () {
        var that = this;
        this.galleryComponent = new GalleryComponent_1.GalleryComponent({
            target: this.$gallery[0],
        });
        this.galleryComponent.on("thumbSelected", function (thumb) {
            that.extensionHost.publish(IIIFEvents_1.IIIFEvents.GALLERY_THUMB_SELECTED, thumb);
            that.extensionHost.publish(IIIFEvents_1.IIIFEvents.THUMB_SELECTED, thumb);
        }, false);
        this.galleryComponent.on("decreaseSize", function () {
            that.extensionHost.publish(IIIFEvents_1.IIIFEvents.GALLERY_DECREASE_SIZE);
        }, false);
        this.galleryComponent.on("increaseSize", function () {
            that.extensionHost.publish(IIIFEvents_1.IIIFEvents.GALLERY_INCREASE_SIZE);
        }, false);
    };
    GalleryView.prototype.databind = function () {
        this.galleryComponent.options.data = this.galleryData;
        this.galleryComponent.set(this.galleryData);
        this.resize();
    };
    GalleryView.prototype.show = function () {
        var _this = this;
        this.isOpen = true;
        this.$element.show();
        // todo: would be better to have no imperative methods on components and use a reactive pattern
        setTimeout(function () {
            _this.galleryComponent.selectIndex(_this.extension.helper.canvasIndex);
            _this.applyExtendedLabelsStyles();
        }, 10);
    };
    GalleryView.prototype.hide = function () {
        this.isOpen = false;
        this.$element.hide();
    };
    GalleryView.prototype.resize = function () {
        _super.prototype.resize.call(this);
        var $main = this.$gallery.find(".main");
        var $header = this.$gallery.find(".header");
        $main.height(this.$element.height() - $header.height());
    };
    GalleryView.prototype.applyExtendedLabelsStyles = function () {
        this.$gallery.addClass("label-extended");
    };
    return GalleryView;
}(BaseView_1.BaseView));
exports.GalleryView = GalleryView;
//# sourceMappingURL=GalleryView.js.map