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
exports.MoreInfoRightPanel = void 0;
var $ = require("jquery");
var IIIFEvents_1 = require("../../IIIFEvents");
var RightPanel_1 = require("../uv-shared-module/RightPanel");
var Utils_1 = require("../../../../Utils");
var Utils_2 = require("../../Utils");
var manifold_1 = require("@iiif/manifold");
var MetadataComponent_1 = require("../uv-shared-module/MetadataComponent");
var MoreInfoRightPanel = /** @class */ (function (_super) {
    __extends(MoreInfoRightPanel, _super);
    function MoreInfoRightPanel($element) {
        return _super.call(this, $element) || this;
    }
    MoreInfoRightPanel.prototype.create = function () {
        var _this = this;
        this.setConfig("moreInfoRightPanel");
        _super.prototype.create.call(this);
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.CANVAS_INDEX_CHANGE, function () {
            _this.databind();
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.RANGE_CHANGE, function () {
            _this.databind();
        });
        this.setTitle(this.config.content.title);
        this.$metadata = $('<article class="iiif-metadata-component"></article>');
        this.$main.append(this.$metadata);
        this.metadataComponent = new MetadataComponent_1.MetadataComponent({
            target: this.$metadata[0],
            data: this._getData(),
        });
        this.metadataComponent.on("iiifViewerLinkClicked", function (href) {
            // Range change.
            var rangeId = Utils_2.Urls.getHashParameterFromString("rid", href);
            // Time change.
            var time = Utils_2.Urls.getHashParameterFromString("t", href);
            if (rangeId && time === null) {
                var range = _this.extension.helper.getRangeById(rangeId);
                if (range) {
                    _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.RANGE_CHANGE, range);
                }
            }
            if (time !== null) {
                var timeAsNumber = Number(time);
                if (!Number.isNaN(timeAsNumber)) {
                    if (rangeId) {
                        // We want to make the time change RELATIVE to the start of the range.
                        var range = _this.extension.helper.getRangeById(rangeId);
                        if (range) {
                            _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.RANGE_TIME_CHANGE, {
                                rangeId: range.id,
                                time: timeAsNumber,
                            });
                        }
                    }
                    else {
                        _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.CURRENT_TIME_CHANGE, timeAsNumber);
                    }
                }
            }
        }, false);
    };
    MoreInfoRightPanel.prototype.toggleFinish = function () {
        _super.prototype.toggleFinish.call(this);
        this.databind();
    };
    MoreInfoRightPanel.prototype.databind = function () {
        this.metadataComponent.set(this._getData());
    };
    MoreInfoRightPanel.prototype._getCurrentRange = function () {
        var range = this.extension.helper.getCurrentRange();
        return range;
    };
    MoreInfoRightPanel.prototype._getData = function () {
        var canvases = this.extension.getCurrentCanvases();
        return {
            canvasDisplayOrder: this.config.options.canvasDisplayOrder,
            canvases: canvases,
            canvasExclude: this.config.options.canvasExclude,
            canvasLabels: this.extension.getCanvasLabels(this.content.page),
            content: this.config.content,
            copiedMessageDuration: 2000,
            copyToClipboardEnabled: Utils_2.Bools.getBool(this.config.options.copyToClipboardEnabled, false),
            helper: this.extension.helper,
            licenseFormatter: new manifold_1.UriLabeller(this.content.license ? this.content.license : {}),
            limit: this.config.options.textLimit || 4,
            limitType: MetadataComponent_1.LimitType.LINES,
            limitToRange: Utils_2.Bools.getBool(this.config.options.limitToRange, false),
            manifestDisplayOrder: this.config.options.manifestDisplayOrder,
            manifestExclude: this.config.options.manifestExclude,
            range: this._getCurrentRange(),
            rtlLanguageCodes: this.config.options.rtlLanguageCodes,
            sanitizer: function (html) {
                return (0, Utils_1.sanitize)(html);
            },
            showAllLanguages: this.config.options.showAllLanguages,
        };
    };
    MoreInfoRightPanel.prototype.resize = function () {
        _super.prototype.resize.call(this);
        this.$main.height(this.$element.height() - this.$top.height() - this.$main.verticalMargins());
        // always put tabindex on, so the main is focusable,
        // just in case there's something wrong with the height
        // comparison below
        this.$main.attr("tabindex", 0);
        this.$main.attr("aria-label", this.config.content.title);
        // if metadata's height lte main's, no scroll, so no focus needed
        // and no aria label either
        if (this.$metadata.height() <= this.$main.height()) {
            this.$main.removeAttr("tabindex");
            this.$main.removeAttr("aria-label");
        }
    };
    return MoreInfoRightPanel;
}(RightPanel_1.RightPanel));
exports.MoreInfoRightPanel = MoreInfoRightPanel;
//# sourceMappingURL=MoreInfoRightPanel.js.map