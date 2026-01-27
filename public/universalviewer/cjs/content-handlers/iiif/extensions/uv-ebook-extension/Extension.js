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
var IIIFEvents_1 = require("../../IIIFEvents");
var BaseExtension_1 = require("../../modules/uv-shared-module/BaseExtension");
var EbookLeftPanel_1 = require("../../modules/uv-ebookleftpanel-module/EbookLeftPanel");
var Events_1 = require("./Events");
var DownloadDialogue_1 = require("./DownloadDialogue");
var EbookCenterPanel_1 = require("../../modules/uv-ebookcenterpanel-module/EbookCenterPanel");
var FooterPanel_1 = require("../../modules/uv-shared-module/FooterPanel");
var MobileFooter_1 = require("../../modules/uv-ebookmobilefooterpanel-module/MobileFooter");
var HeaderPanel_1 = require("../../modules/uv-shared-module/HeaderPanel");
var MoreInfoDialogue_1 = require("../../modules/uv-dialogues-module/MoreInfoDialogue");
var MoreInfoRightPanel_1 = require("../../modules/uv-moreinforightpanel-module/MoreInfoRightPanel");
var SettingsDialogue_1 = require("./SettingsDialogue");
var ShareDialogue_1 = require("./ShareDialogue");
var utils_1 = require("@edsilv/utils");
require("./theme/theme.less");
var config_json_1 = __importDefault(require("./config/config.json"));
var Extension = /** @class */ (function (_super) {
    __extends(Extension, _super);
    function Extension() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.defaultConfig = config_json_1.default;
        _this.locales = {
            "en-GB": config_json_1.default,
        };
        return _this;
    }
    Extension.prototype.create = function () {
        var _this = this;
        _super.prototype.create.call(this);
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.CANVAS_INDEX_CHANGE, function (canvasIndex) {
            _this.viewCanvas(canvasIndex);
        });
        this.extensionHost.subscribe(Events_1.EbookExtensionEvents.CFI_FRAGMENT_CHANGE, function (cfi) {
            _this.cfiFragement = cfi;
            _this.fire(Events_1.EbookExtensionEvents.CFI_FRAGMENT_CHANGE, _this.cfiFragement);
        });
    };
    Extension.prototype.createModules = function () {
        _super.prototype.createModules.call(this);
        if (this.isHeaderPanelEnabled()) {
            this.headerPanel = new HeaderPanel_1.HeaderPanel(this.shell.$headerPanel);
        }
        else {
            this.shell.$headerPanel.hide();
        }
        if (this.isLeftPanelEnabled()) {
            this.leftPanel = new EbookLeftPanel_1.EbookLeftPanel(this.shell.$leftPanel);
        }
        else {
            this.shell.$leftPanel.hide();
        }
        this.centerPanel = new EbookCenterPanel_1.EbookCenterPanel(this.shell.$centerPanel);
        if (this.isRightPanelEnabled()) {
            this.rightPanel = new MoreInfoRightPanel_1.MoreInfoRightPanel(this.shell.$rightPanel);
        }
        else {
            this.shell.$rightPanel.hide();
        }
        if (this.isFooterPanelEnabled()) {
            this.footerPanel = new FooterPanel_1.FooterPanel(this.shell.$footerPanel);
            this.mobileFooterPanel = new MobileFooter_1.FooterPanel(this.shell.$mobileFooterPanel);
        }
        else {
            this.shell.$footerPanel.hide();
        }
        this.$moreInfoDialogue = $('<div class="overlay moreInfo" aria-hidden="true"></div>');
        this.shell.$overlays.append(this.$moreInfoDialogue);
        this.moreInfoDialogue = new MoreInfoDialogue_1.MoreInfoDialogue(this.$moreInfoDialogue);
        this.$shareDialogue = $('<div class="overlay share" aria-hidden="true"></div>');
        this.shell.$overlays.append(this.$shareDialogue);
        this.shareDialogue = new ShareDialogue_1.ShareDialogue(this.$shareDialogue);
        this.$downloadDialogue = $('<div class="overlay download" aria-hidden="true" role="region"></div>');
        this.shell.$overlays.append(this.$downloadDialogue);
        this.downloadDialogue = new DownloadDialogue_1.DownloadDialogue(this.$downloadDialogue);
        this.$settingsDialogue = $('<div class="overlay settings" aria-hidden="true"></div>');
        this.shell.$overlays.append(this.$settingsDialogue);
        this.settingsDialogue = new SettingsDialogue_1.SettingsDialogue(this.$settingsDialogue);
        if (this.isHeaderPanelEnabled()) {
            this.headerPanel.init();
        }
        if (this.isLeftPanelEnabled()) {
            this.leftPanel.init();
        }
        if (this.isRightPanelEnabled()) {
            this.rightPanel.init();
        }
        if (this.isFooterPanelEnabled()) {
            this.footerPanel.init();
        }
    };
    Extension.prototype.isLeftPanelEnabled = function () {
        return true;
    };
    Extension.prototype.render = function () {
        _super.prototype.render.call(this);
        this.checkForCFIParam();
    };
    Extension.prototype.getEmbedScript = function (template, width, height) {
        var appUri = this.getAppUri();
        var iframeSrc = "".concat(appUri, "#?manifest=").concat(this.helper.manifestUri, "&cfi=").concat(this.cfiFragement);
        var script = utils_1.Strings.format(template, iframeSrc, width.toString(), height.toString());
        return script;
    };
    Extension.prototype.checkForCFIParam = function () {
        var cfi = this.data.cfi;
        if (cfi) {
            this.extensionHost.publish(Events_1.EbookExtensionEvents.CFI_FRAGMENT_CHANGE, cfi);
        }
    };
    return Extension;
}(BaseExtension_1.BaseExtension));
exports.default = Extension;
//# sourceMappingURL=Extension.js.map