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
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OpenSeadragonCenterPanel = void 0;
var $ = require("jquery");
var Utils_1 = require("../../Utils");
var Utils_2 = require("../../../../Utils");
var vocabulary_1 = require("@iiif/vocabulary");
var IIIFEvents_1 = require("../../IIIFEvents");
var XYWHFragment_1 = require("../uv-shared-module/XYWHFragment");
var CenterPanel_1 = require("../uv-shared-module/CenterPanel");
var Events_1 = require("../../extensions/uv-openseadragon-extension/Events");
var openseadragon_1 = __importDefault(require("openseadragon"));
require("@openseadragon-imaging/openseadragon-viewerinputhook");
var dist_commonjs_1 = require("@iiif/vocabulary/dist-commonjs");
var Events_2 = require("../../../../Events");
var OpenSeadragonCenterPanel = /** @class */ (function (_super) {
    __extends(OpenSeadragonCenterPanel, _super);
    function OpenSeadragonCenterPanel($element) {
        var _this = _super.call(this, $element) || this;
        _this.controlsVisible = false;
        _this.isCreated = false;
        _this.isLoaded = false;
        _this.isFirstLoad = true;
        _this.navigatedFromSearch = false;
        _this.nextButtonEnabled = false;
        // pages: IExternalResource[];
        _this.prevButtonEnabled = false;
        return _this;
    }
    OpenSeadragonCenterPanel.prototype.create = function () {
        var _this = this;
        this.setConfig("openSeadragonCenterPanel");
        _super.prototype.create.call(this);
        this.viewerId = "osd" + new Date().getTime();
        this.$viewer = $('<div id="' + this.viewerId + '" class="viewer"></div>');
        this.$content.prepend(this.$viewer);
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.ANNOTATIONS, function (args) {
            _this.overlayAnnotations();
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.SETTINGS_CHANGE, function (args) {
            _this.viewer.gestureSettingsMouse.clickToZoom = args.clickToZoomEnabled;
            _this.viewer.controlsFadeLength = _this.getControlsFadeLength();
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.OPEN_EXTERNAL_RESOURCE, function (resources) {
            _this.whenResized(function () { return __awaiter(_this, void 0, void 0, function () {
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            if (!this.isCreated) {
                                // uv may have reloaded
                                this.createUI();
                            }
                            this.isLoaded = false;
                            return [4 /*yield*/, this.openMedia(resources)];
                        case 1:
                            _a.sent();
                            this.isLoaded = true;
                            this.extensionHost.publish(Events_2.Events.EXTERNAL_RESOURCE_OPENED);
                            this.extensionHost.publish(Events_2.Events.LOAD);
                            return [2 /*return*/];
                    }
                });
            }); });
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.CLEAR_ANNOTATIONS, function () {
            _this.whenCreated(function () {
                _this.extension.currentAnnotationRect = null;
                _this.clearAnnotations();
            });
        });
        this.extensionHost.subscribe(Events_1.OpenSeadragonExtensionEvents.NEXT_SEARCH_RESULT, function () {
            _this.whenCreated(function () {
                _this.nextAnnotation();
            });
        });
        this.extensionHost.subscribe(Events_1.OpenSeadragonExtensionEvents.PREV_SEARCH_RESULT, function () {
            _this.whenCreated(function () {
                _this.prevAnnotation();
            });
        });
        this.extensionHost.subscribe(Events_1.OpenSeadragonExtensionEvents.ZOOM_IN, function () {
            _this.whenCreated(function () {
                _this.zoomIn();
            });
        });
        this.extensionHost.subscribe(Events_1.OpenSeadragonExtensionEvents.ZOOM_OUT, function () {
            _this.whenCreated(function () {
                _this.zoomOut();
            });
        });
        this.extensionHost.subscribe(Events_1.OpenSeadragonExtensionEvents.ROTATE, function () {
            _this.whenCreated(function () {
                _this.rotateRight();
            });
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.METRIC_CHANGE, function () {
            _this.whenCreated(function () {
                _this.updateResponsiveView();
            });
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.SET_TARGET, function (target) {
            _this.whenLoaded(function () {
                _this.fitToBounds(target, false);
            });
        });
        this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.SET_ROTATION, function (rotation) {
            _this.whenLoaded(function () {
                _this.viewer.viewport.setRotation(rotation);
            });
        });
        this.extensionHost.subscribe(Events_1.OpenSeadragonExtensionEvents.CHOICE_CHANGE, function (_a) {
            var canvasId = _a.canvasId, choiceIndex = _a.choiceIndex;
            _this.whenCreated(function () {
                var world = _this.viewer.world;
                var indices = _this.extension.getPagedIndices();
                var worldIndex = 0;
                indices.forEach(function (index) {
                    var canvas = _this.extension.helper.getCanvasByIndex(index);
                    var numChoices = canvas.getChoices().length;
                    // need to count a canvas with "zero" choices as 1
                    var worldItemCount = numChoices === 0 ? 1 : numChoices;
                    if (canvas.id === canvasId) {
                        for (var c = 0; c < numChoices; c++) {
                            var item = world.getItemAt(worldIndex);
                            if (item) {
                                item.setOpacity(c === choiceIndex ? 1 : 0);
                            }
                            worldIndex++;
                        }
                    }
                    else {
                        worldIndex += worldItemCount;
                    }
                });
            });
        });
    };
    OpenSeadragonCenterPanel.prototype.whenCreated = function (cb) {
        var _this = this;
        Utils_1.Async.waitFor(function () {
            return _this.isCreated;
        }, cb);
    };
    OpenSeadragonCenterPanel.prototype.whenLoaded = function (cb) {
        var _this = this;
        Utils_1.Async.waitFor(function () {
            return _this.isLoaded;
        }, cb);
    };
    OpenSeadragonCenterPanel.prototype.zoomIn = function () {
        this.viewer.viewport.zoomTo(this.viewer.viewport.getZoom(true) * 2);
    };
    OpenSeadragonCenterPanel.prototype.zoomOut = function () {
        this.viewer.viewport.zoomTo(this.viewer.viewport.getZoom(true) * 0.5);
    };
    OpenSeadragonCenterPanel.prototype.rotateRight = function () {
        this.viewer.viewport.setRotation(this.viewer.viewport.getRotation() + 90);
    };
    OpenSeadragonCenterPanel.prototype.updateResponsiveView = function () {
        var _this = this;
        this.setNavigatorVisible();
        this.viewer.autoHideControls = this.extension.isDesktopMetric();
        var enableAutoHide = function (event) {
            _this.viewer.autoHideControls = true;
        };
        var disableAutoHide = function () {
            _this.viewer.autoHideControls = false;
        };
        var buttons = [
            this.$zoomInButton,
            this.$zoomOutButton,
            this.$goHomeButton,
            this.$rotateButton,
            this.$adjustImageButton,
        ];
        buttons.forEach(function (button) {
            button.on("focus", disableAutoHide);
            button.on("focusout", enableAutoHide);
        });
    };
    OpenSeadragonCenterPanel.prototype.createUI = function () {
        return __awaiter(this, void 0, void 0, function () {
            var pixel, that, debouncedDoubleClick, $oldZoomIn, $oldZoomOut, $oldGoHome, $oldRotate, settings, contrastPercent, brightnessPercent, saturationPercent;
            var _this = this;
            var _a;
            return __generator(this, function (_b) {
                this.$spinner = $('<div class="spinner"></div>');
                this.$content.append(this.$spinner);
                this.showAdjustImageButton = Utils_1.Bools.getBool(this.config.options.showAdjustImageControl, false);
                pixel = "data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==";
                this.viewer = (0, openseadragon_1.default)({
                    // id: this.viewerId,
                    element: this.$viewer[0],
                    drawer: "auto",
                    crossOriginPolicy: "Anonymous",
                    showNavigationControl: true,
                    showNavigator: true,
                    showRotationControl: true,
                    showHomeControl: Utils_1.Bools.getBool(this.config.options.showHomeControl, false),
                    showFullPageControl: false,
                    defaultZoomLevel: this.config.options.defaultZoomLevel || 0,
                    maxZoomPixelRatio: this.config.options.maxZoomPixelRatio || 2,
                    controlsFadeDelay: this.config.options.controlsFadeDelay || 250,
                    controlsFadeLength: this.getControlsFadeLength(),
                    navigatorPosition: (this.extension.helper.isContinuous()
                        ? "BOTTOM_LEFT"
                        : this.config.options.navigatorPosition ||
                            "BOTTOM_RIGHT"),
                    navigatorHeight: "100px",
                    navigatorWidth: "100px",
                    navigatorMaintainSizeRatio: false,
                    animationTime: this.config.options.animationTime || 1.2,
                    visibilityRatio: this.config.options.visibilityRatio || 0.5,
                    constrainDuringPan: Utils_1.Bools.getBool(this.config.options.constrainDuringPan, false),
                    immediateRender: Utils_1.Bools.getBool(this.config.options.immediateRender, false),
                    blendTime: this.config.options.blendTime || 0,
                    autoHideControls: Utils_1.Bools.getBool(this.config.options.autoHideControls, true),
                    prefixUrl: undefined,
                    gestureSettingsMouse: {
                        clickToZoom: Utils_1.Bools.getBool(this.extension.data.config.options.clickToZoomEnabled, true),
                    },
                    navImages: {
                        zoomIn: {
                            REST: pixel,
                            GROUP: pixel,
                            HOVER: pixel,
                            DOWN: pixel,
                        },
                        zoomOut: {
                            REST: pixel,
                            GROUP: pixel,
                            HOVER: pixel,
                            DOWN: pixel,
                        },
                        home: {
                            REST: pixel,
                            GROUP: pixel,
                            HOVER: pixel,
                            DOWN: pixel,
                        },
                        rotateright: {
                            REST: pixel,
                            GROUP: pixel,
                            HOVER: pixel,
                            DOWN: pixel,
                        },
                        rotateleft: {
                            REST: pixel,
                            GROUP: pixel,
                            HOVER: pixel,
                            DOWN: pixel,
                        },
                        next: {
                            REST: pixel,
                            GROUP: pixel,
                            HOVER: pixel,
                            DOWN: pixel,
                        },
                        previous: {
                            REST: pixel,
                            GROUP: pixel,
                            HOVER: pixel,
                            DOWN: pixel,
                        },
                        fullpage: {
                            REST: pixel,
                            GROUP: pixel,
                            HOVER: pixel,
                            DOWN: pixel,
                        },
                        flip: {
                            REST: pixel,
                            GROUP: pixel,
                            HOVER: pixel,
                            DOWN: pixel,
                        },
                    },
                    // The max number of milliseconds that an image job may take to complete.
                    timeout: this.config.options.tileTimeout || 30000,
                });
                that = this;
                debouncedDoubleClick = (0, Utils_2.debounce)(function (e) {
                    var canvas = that.extension.helper.getCurrentCanvas();
                    var viewportPoint = that.viewer.viewport.pointFromPixel(e.position);
                    var imagePoint = that.viewer.viewport.viewportToImageCoordinates(viewportPoint.x, viewportPoint.y);
                    _this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.DOUBLECLICK, {
                        target: "".concat(canvas.id, "#xywh=").concat(Math.round(imagePoint.x), ",").concat(Math.round(imagePoint.y), ",1,1"),
                    });
                }, 100);
                this.viewer.addViewerInputHook({
                    hooks: [
                        {
                            tracker: "viewer",
                            handler: "dblClickHandler",
                            hookHandler: function (e) {
                                var settings = _this.extension.getSettings();
                                var pagingAvailable = _this.extension.helper.isPagingAvailable();
                                if ((pagingAvailable && !settings.pagingEnabled) ||
                                    !pagingAvailable) {
                                    if (_this.config.options.doubleClickAnnotationEnabled) {
                                        debouncedDoubleClick(e);
                                    }
                                }
                            },
                        },
                    ],
                });
                $oldZoomIn = this.$viewer.find('div[title="Zoom in"]');
                this.$zoomInButton = $("<button />").append($oldZoomIn.contents());
                this.$zoomInButton.insertAfter($oldZoomIn);
                $oldZoomIn.remove();
                this.$zoomInButton.attr("tabindex", 0);
                this.$zoomInButton.attr("title", this.content.zoomIn);
                this.$zoomInButton.attr("aria-label", this.content.zoomIn);
                this.$zoomInButton.addClass("zoomIn viewportNavButton");
                this.onAccessibleClick(this.$zoomInButton, function () {
                    if (_this.viewer.viewport.getZoom() < _this.viewer.viewport.getMaxZoom())
                        _this.zoomIn();
                });
                $oldZoomOut = this.$viewer.find('div[title="Zoom out"]');
                this.$zoomOutButton = $("<button />").append($oldZoomOut.contents());
                this.$zoomOutButton.insertAfter($oldZoomOut);
                $oldZoomIn.remove();
                this.$zoomOutButton.attr("tabindex", 0);
                this.$zoomOutButton.attr("title", this.content.zoomOut);
                this.$zoomOutButton.attr("aria-label", this.content.zoomOut);
                this.$zoomOutButton.addClass("zoomOut viewportNavButton");
                this.onAccessibleClick(this.$zoomOutButton, function () {
                    if (_this.viewer.viewport.getZoom() > _this.viewer.viewport.getMinZoom())
                        _this.zoomOut();
                });
                $oldGoHome = this.$viewer.find('div[title="Go home"]');
                this.$goHomeButton = $("<button />").append($oldGoHome.contents());
                this.$goHomeButton.insertAfter($oldGoHome);
                $oldGoHome.remove();
                this.$goHomeButton.attr("tabindex", 0);
                this.$goHomeButton.attr("title", this.content.goHome);
                this.$goHomeButton.attr("aria-label", this.content.goHome);
                this.$goHomeButton.addClass("goHome viewportNavButton");
                this.onAccessibleClick(this.$goHomeButton, function () {
                    _this.goHome();
                });
                $oldRotate = this.$viewer.find('div[title="Rotate right"]');
                this.$rotateButton = $("<button />").append($oldRotate.contents());
                this.$rotateButton.insertAfter($oldRotate);
                $oldRotate.remove();
                this.$rotateButton.attr("tabindex", 0);
                this.$rotateButton.attr("title", this.content.rotateRight);
                this.$rotateButton.attr("aria-label", this.content.rotateRight);
                this.$rotateButton.addClass("rotate viewportNavButton");
                this.onAccessibleClick(this.$rotateButton, function () {
                    _this.rotateRight();
                });
                if (this.showAdjustImageButton) {
                    this.$adjustImageButton = this.$rotateButton.clone();
                    this.$adjustImageButton.attr("title", this.content.adjustImage);
                    this.$adjustImageButton.attr("aria-label", this.content.adjustImage);
                    this.$adjustImageButton.switchClass("rotate", "adjustImage");
                    this.$adjustImageButton.attr("tabindex", 0);
                    this.$adjustImageButton.onPressed(function () {
                        _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.SHOW_ADJUSTIMAGE_DIALOGUE);
                    });
                    this.$adjustImageButton.insertAfter(this.$rotateButton);
                    this.onAccessibleClick(this.$adjustImageButton, function () {
                        _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.SHOW_ADJUSTIMAGE_DIALOGUE);
                    });
                }
                this.$zoomInButton
                    .add(this.$zoomOutButton)
                    .add(this.$goHomeButton)
                    .add(this.$rotateButton)
                    .add(this.$adjustImageButton)
                    .on("focus", function () {
                    if (_this.controlsVisible)
                        return;
                    _this.controlsVisible = true;
                    _this.viewer.setControlsEnabled(true);
                });
                this.$zoomInButton.add(this.$adjustImageButton).on("blur", function () {
                    if (!_this.controlsVisible)
                        return;
                    _this.controlsVisible = false;
                    _this.viewer.setControlsEnabled(false);
                });
                this.$viewportNavButtonsContainer = this.$viewer.find(".openseadragon-container > div:not(.openseadragon-canvas):first");
                //this.$viewportNavButtonsContainer.addClass("viewportControls");
                this.$viewportNavButtons =
                    this.$viewportNavButtonsContainer.find(".viewportNavButton");
                this.$canvas = $(this.viewer.canvas);
                this.$canvas.attr("role", "application");
                this.$canvas.attr("aria-label", this.content.mediaViewer);
                settings = this.extension.getSettings();
                if (((_a = this.extension.data.config) === null || _a === void 0 ? void 0 : _a.options.saveUserSettings) &&
                    settings.rememberSettings) {
                    contrastPercent = settings.contrastPercent;
                    brightnessPercent = settings.brightnessPercent;
                    saturationPercent = settings.saturationPercent;
                    this.$canvas[0].children[0].style.filter =
                        "contrast(".concat(contrastPercent, "%) brightness(").concat(brightnessPercent, "%) saturate(").concat(saturationPercent, "%)");
                }
                // disable right click on canvas
                this.$canvas.on("contextmenu", function () {
                    return false;
                });
                this.$navigator = this.$viewer.find(".navigator");
                this.setNavigatorVisible();
                // events
                this.$element.on("mousemove", function () {
                    if (_this.controlsVisible)
                        return;
                    _this.controlsVisible = true;
                    _this.viewer.setControlsEnabled(true);
                });
                this.$element.on("mouseleave", function () {
                    if (!_this.controlsVisible)
                        return;
                    // don't hide controls if a dialog overlay (e.g. choice menu) is visible
                    if ($(".overlay:visible").length)
                        return;
                    _this.controlsVisible = false;
                    _this.viewer.setControlsEnabled(false);
                });
                // when mouse move stopped
                this.$element.on(
                //@ts-ignore
                "mousemove", function () {
                    // if over element, hide controls.
                    // When over prev/next buttons keep controls enabled
                    if (_this.$prevButton.ismouseover()) {
                        return;
                    }
                    if (_this.$nextButton.ismouseover()) {
                        return;
                    }
                    // don't hide controls if a dialog overlay (e.g. choice menu) is visible
                    if ($(".overlay:visible").length)
                        return;
                    if (!_this.$viewer.find(".navigator").ismouseover()) {
                        if (!_this.controlsVisible)
                            return;
                        _this.controlsVisible = false;
                        _this.viewer.setControlsEnabled(false);
                    }
                }, this.config.options.controlsFadeAfterInactive);
                //this.viewer.addHandler("open-failed", () => {
                //});
                this.viewer.addHandler("resize", function (viewer) {
                    _this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.OPENSEADRAGON_RESIZE, viewer);
                    _this.viewerResize(viewer);
                });
                this.viewer.addHandler("animation-start", function (viewer) {
                    _this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.OPENSEADRAGON_ANIMATION_START, viewer);
                });
                this.viewer.addHandler("animation", function (viewer) {
                    _this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.OPENSEADRAGON_ANIMATION, viewer);
                });
                this.viewer.addHandler("animation-finish", function (viewer) {
                    _this.currentBounds = _this.getViewportBounds();
                    _this.updateVisibleAnnotationRects();
                    _this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.OPENSEADRAGON_ANIMATION_FINISH, viewer);
                });
                this.viewer.addHandler("rotate", function (args) {
                    // console.log("rotate");
                    _this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.OPENSEADRAGON_ROTATION, args.degrees);
                });
                this.title = this.extension.helper.getLabel();
                this.createNavigationButtons();
                this.hidePrevButton();
                this.hideNextButton();
                this.createChoiceSwitch();
                this.isCreated = true;
                //this.resize();
                // check if initial interaction is keyboard navigation or mouse
                // this prevents blue focus border from appearing on first mouse interaction
                document.addEventListener("keydown", function (e) {
                    var _a;
                    if (e.key === "Tab") {
                        (_a = _this.$canvas) === null || _a === void 0 ? void 0 : _a.addClass("keyboard-nav");
                    }
                }, { capture: true });
                document.addEventListener("pointerdown", function () {
                    var _a;
                    (_a = _this.$canvas) === null || _a === void 0 ? void 0 : _a.removeClass("keyboard-nav");
                }, { capture: true });
                this.extensionHost.subscribe(IIIFEvents_1.IIIFEvents.CLOSE_ACTIVE_DIALOGUE, function () {
                    _this.$viewer.removeClass("dialogue-open");
                });
                return [2 /*return*/];
            });
        });
    };
    OpenSeadragonCenterPanel.prototype.createNavigationButtons = function () {
        var _this = this;
        var viewingDirection = this.extension.helper.getViewingDirection() ||
            vocabulary_1.ViewingDirection.LEFT_TO_RIGHT;
        this.$prevButton = $("<button class=\"btn btn-default paging prev\" title=\"".concat(this.content.previousImage, "\">\n          <i class=\"uv-icon-prev\" aria-hidden=\"true\"></i>\n          <span class=\"sr-only\">").concat(this.content.previousImage, "</span>\n        </button>"));
        if (this.extension.helper.isRightToLeft()) {
            this.$prevButton
                .prop("title", this.content.nextImage)
                .attr("aria-label", this.content.nextImage);
        }
        else {
            this.$prevButton
                .prop("title", this.content.previousImage)
                .attr("aria-label", this.content.previousImage);
        }
        this.$nextButton = $("<button class=\"btn btn-default paging next\" title=\"".concat(this.content.nextImage, "\">\n        <i class=\"uv-icon-next\" aria-hidden=\"true\"></i>\n        <span class=\"sr-only\">").concat(this.content.nextImage, "</span>\n      </button>"));
        if (this.extension.helper.isRightToLeft()) {
            this.$nextButton
                .prop("title", this.content.previousImage)
                .attr("aria-label", this.content.previousImage);
        }
        else {
            this.$nextButton
                .prop("title", this.content.nextImage)
                .attr("aria-label", this.content.nextImage);
        }
        this.viewer.addControl(this.$prevButton[0], {
            anchor: openseadragon_1.default.ControlAnchor.TOP_LEFT,
        });
        this.viewer.addControl(this.$nextButton[0], {
            anchor: openseadragon_1.default.ControlAnchor.TOP_RIGHT,
        });
        switch (viewingDirection) {
            case vocabulary_1.ViewingDirection.BOTTOM_TO_TOP:
            case vocabulary_1.ViewingDirection.TOP_TO_BOTTOM:
                this.$prevButton.addClass("vertical");
                this.$nextButton.addClass("vertical");
                break;
        }
        var that = this;
        this.onAccessibleClick(this.$prevButton, function (e) {
            e.preventDefault();
            openseadragon_1.default.cancelEvent(e);
            if (!that.prevButtonEnabled)
                return;
            switch (viewingDirection) {
                case vocabulary_1.ViewingDirection.LEFT_TO_RIGHT:
                case vocabulary_1.ViewingDirection.BOTTOM_TO_TOP:
                case vocabulary_1.ViewingDirection.TOP_TO_BOTTOM:
                    _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.PREV);
                    break;
                case vocabulary_1.ViewingDirection.RIGHT_TO_LEFT:
                    _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.NEXT);
                    break;
            }
        });
        this.onAccessibleClick(this.$nextButton, function (e) {
            e.preventDefault();
            openseadragon_1.default.cancelEvent(e);
            if (!that.nextButtonEnabled)
                return;
            switch (viewingDirection) {
                case vocabulary_1.ViewingDirection.LEFT_TO_RIGHT:
                case vocabulary_1.ViewingDirection.BOTTOM_TO_TOP:
                case vocabulary_1.ViewingDirection.TOP_TO_BOTTOM:
                    _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.NEXT);
                    break;
                case vocabulary_1.ViewingDirection.RIGHT_TO_LEFT:
                    _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.PREV);
                    break;
            }
        });
        // When Prev/Next buttons are focused, make sure the controls are enabled
        this.$prevButton.add(this.$nextButton).on("focus", function () {
            if (_this.controlsVisible)
                return;
            _this.controlsVisible = true;
            _this.viewer.setControlsEnabled(true);
        });
        this.$prevButton.add(this.$nextButton).on("blur", function () {
            if (!_this.controlsVisible)
                return;
            _this.controlsVisible = false;
            _this.viewer.setControlsEnabled(false);
        });
    };
    OpenSeadragonCenterPanel.prototype.createChoiceSwitch = function () {
        var _this = this;
        this.$choiceSwitchButton = this.$rotateButton.clone();
        this.$choiceSwitchButton.attr("aria-label", this.content.layers);
        this.$choiceSwitchButton.attr("title", this.content.layers);
        this.$choiceSwitchButton.switchClass("rotate", "choiceSwitch");
        this.$choiceSwitchButton.attr("tabindex", 0);
        if (this.showAdjustImageButton && this.$adjustImageButton) {
            this.$choiceSwitchButton.insertAfter(this.$adjustImageButton);
        }
        else {
            this.$choiceSwitchButton.insertAfter(this.$rotateButton);
        }
        this.onAccessibleClick(this.$choiceSwitchButton, function () {
            _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.SHOW_CHOICE_SWITCH_DIALOGUE);
        });
    };
    OpenSeadragonCenterPanel.prototype.getGirderTileSource = function () {
        return __awaiter(this, void 0, void 0, function () {
            var _this = this;
            return __generator(this, function (_a) {
                return [2 /*return*/, new Promise(function (resolve) {
                        var canvas = _this.extension.helper.getCurrentCanvas();
                        var annotations = canvas.getContent();
                        if (annotations.length) {
                            var annotation = annotations[0];
                            var body = annotation.getBody();
                            if (body.length) {
                                var services = body[0].getServices();
                                if (services.length) {
                                    var id = services[0].id;
                                    var tileDescriptor_1 = id;
                                    if (!tileDescriptor_1.endsWith("/")) {
                                        tileDescriptor_1 += "/";
                                    }
                                    tileDescriptor_1 += "tiles";
                                    if (id.endsWith("/")) {
                                        id = id.substr(0, id.length - 1);
                                    }
                                    fetch(tileDescriptor_1)
                                        .then(function (response) { return response.json(); })
                                        .then(function (info) {
                                        var tileSource = {
                                            height: info.sizeY,
                                            width: info.sizeX,
                                            tileWidth: info.tileWidth,
                                            tileHeight: info.tileHeight,
                                            minLevel: 0,
                                            maxLevel: info.levels - 1,
                                            units: "mm",
                                            spacing: [info.mm_x, info.mm_y],
                                            getTileUrl: function (level, x, y, query) {
                                                var url = tileDescriptor_1 + "/zxy/" + level + "/" + x + "/" + y;
                                                if (query) {
                                                    url += "?" + $.param(query);
                                                }
                                                return url;
                                            },
                                        };
                                        if (!info.mm_x) {
                                            tileSource.units = "pixels";
                                            tileSource.spacing = [1, 1];
                                        }
                                        resolve(tileSource);
                                    });
                                }
                            }
                        }
                    })];
            });
        });
    };
    OpenSeadragonCenterPanel.prototype.openMedia = function (resources) {
        return __awaiter(this, void 0, void 0, function () {
            var spinnerTimeout, images, indices, hasChoices, canvasData, positioned, totalItems_1, _i, canvasData_1, data, loadedItems_1, isGirder, i, data, tileSource, _a;
            var _this = this;
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        // uv may have been unloaded
                        if (!this.viewer) {
                            return [2 /*return*/];
                        }
                        this.viewer.close();
                        this.items = [];
                        spinnerTimeout = setTimeout(function () {
                            _this.$spinner.show();
                        }, 200);
                        return [4 /*yield*/, this.extension.getExternalResources(resources)];
                    case 1:
                        images = _b.sent();
                        indices = this.extension.getPagedIndices();
                        hasChoices = indices.some(function (index) {
                            var canvas = _this.extension.helper.getCanvasByIndex(index);
                            return canvas.getChoices().length > 0;
                        });
                        if (hasChoices) {
                            try {
                                canvasData = indices.map(function (index) {
                                    var canvas = _this.extension.helper.getCanvasByIndex(index);
                                    return {
                                        index: index,
                                        canvas: canvas,
                                        choices: canvas.getChoices(),
                                        width: canvas.getWidth(),
                                        height: canvas.getHeight(),
                                        x: 0,
                                        y: 0,
                                    };
                                });
                                positioned = this.getPagePositions(canvasData);
                                totalItems_1 = 0;
                                for (_i = 0, canvasData_1 = canvasData; _i < canvasData_1.length; _i++) {
                                    data = canvasData_1[_i];
                                    totalItems_1 += data.choices.length;
                                }
                                loadedItems_1 = 0;
                                positioned.forEach(function (data) {
                                    if (data.choices.length === 0) {
                                        // no choices on this canvas, load as regular image
                                        var content = data.canvas.getContent();
                                        if (content.length) {
                                            var body = content[0].getBody();
                                            if (body.length) {
                                                var services = body[0].getServices();
                                                var tileSource = void 0;
                                                if (services.length) {
                                                    var id = services[0].id;
                                                    if (!id.endsWith("/"))
                                                        id += "/";
                                                    tileSource = id + "info.json";
                                                }
                                                else {
                                                    tileSource = {
                                                        type: "image",
                                                        url: body[0].id,
                                                        buildPyramid: false,
                                                    };
                                                }
                                                totalItems_1++;
                                                _this.viewer.addTiledImage({
                                                    tileSource: tileSource,
                                                    x: data.x,
                                                    y: data.y,
                                                    width: data.width,
                                                    success: function (item) {
                                                        _this.items.push(item);
                                                        loadedItems_1++;
                                                        if (loadedItems_1 === totalItems_1) {
                                                            clearTimeout(spinnerTimeout);
                                                            _this.$spinner.hide();
                                                            _this.openPagesHandler();
                                                            _this.resize();
                                                            _this.goHome();
                                                        }
                                                    },
                                                });
                                            }
                                        }
                                    }
                                    else {
                                        data.choices.forEach(function (choice, index) {
                                            var services = choice.getServices();
                                            var tileSource;
                                            if (services.length) {
                                                var id = services[0].id;
                                                if (!id.endsWith("/"))
                                                    id += "/";
                                                tileSource = id + "info.json";
                                            }
                                            else {
                                                tileSource = {
                                                    type: "image",
                                                    url: choice.id,
                                                    buildPyramid: false,
                                                };
                                            }
                                            _this.viewer.addTiledImage({
                                                tileSource: tileSource,
                                                x: data.x,
                                                y: data.y,
                                                width: data.width,
                                                opacity: index === 0 ? 1 : 0,
                                                success: function (item) {
                                                    _this.items.push(item);
                                                    loadedItems_1++;
                                                    if (loadedItems_1 === totalItems_1) {
                                                        clearTimeout(spinnerTimeout);
                                                        _this.$spinner.hide();
                                                        _this.openPagesHandler();
                                                        _this.resize();
                                                        _this.goHome();
                                                    }
                                                },
                                            });
                                        });
                                    }
                                });
                            }
                            catch (e) {
                                console.error(e);
                            }
                            return [2 /*return*/];
                        }
                        isGirder = this.extension.format === dist_commonjs_1.MediaType.GIRDER;
                        _b.label = 2;
                    case 2:
                        _b.trys.push([2, 10, , 11]);
                        this.viewer.close();
                        images = this.getPagePositions(images);
                        i = 0;
                        _b.label = 3;
                    case 3:
                        if (!(i < images.length)) return [3 /*break*/, 9];
                        data = images[i];
                        tileSource = void 0;
                        if (!data.hasServiceDescriptor) return [3 /*break*/, 4];
                        // use the info.json descriptor
                        tileSource = data;
                        return [3 /*break*/, 7];
                    case 4:
                        if (!isGirder) return [3 /*break*/, 6];
                        return [4 /*yield*/, this.getGirderTileSource()];
                    case 5:
                        // load girder image
                        tileSource = _b.sent();
                        return [3 /*break*/, 7];
                    case 6:
                        // load image without tiling
                        tileSource = {
                            type: "image",
                            url: data.id,
                            buildPyramid: false,
                        };
                        _b.label = 7;
                    case 7:
                        this.viewer.addTiledImage({
                            tileSource: tileSource,
                            x: data.x,
                            y: data.y,
                            width: data.width,
                            success: function (item) {
                                _this.items.push(item);
                                if (_this.items.length === images.length) {
                                    clearTimeout(spinnerTimeout);
                                    _this.$spinner.hide();
                                    _this.openPagesHandler();
                                }
                                _this.resize();
                                _this.goHome();
                            },
                        });
                        _b.label = 8;
                    case 8:
                        i++;
                        return [3 /*break*/, 3];
                    case 9: return [3 /*break*/, 11];
                    case 10:
                        _a = _b.sent();
                        return [3 /*break*/, 11];
                    case 11: return [2 /*return*/];
                }
            });
        });
    };
    OpenSeadragonCenterPanel.prototype.getPagePositions = function (resources) {
        var leftPage;
        var rightPage;
        var topPage;
        var bottomPage;
        var page;
        var nextPage;
        // if there's more than one image, determine alignment strategy
        if (resources.length > 1) {
            if (resources.length === 2) {
                // recto verso
                if (this.extension.helper.isVerticallyAligned()) {
                    // vertical alignment
                    topPage = resources[0];
                    topPage.y = 0;
                    bottomPage = resources[1];
                    bottomPage.y = topPage.height + this.config.options.pageGap;
                }
                else {
                    // horizontal alignment
                    leftPage = resources[0];
                    leftPage.x = 0;
                    rightPage = resources[1];
                    rightPage.x = leftPage.width + this.config.options.pageGap;
                }
            }
            else {
                // scroll
                if (this.extension.helper.isVerticallyAligned()) {
                    // vertical alignment
                    if (this.extension.helper.isTopToBottom()) {
                        // top to bottom
                        for (var i = 0; i < resources.length - 1; i++) {
                            page = resources[i];
                            nextPage = resources[i + 1];
                            nextPage.y = (page.y || 0) + page.height;
                        }
                    }
                    else {
                        // bottom to top
                        for (var i = resources.length; i > 0; i--) {
                            page = resources[i];
                            nextPage = resources[i - 1];
                            nextPage.y = (page.y || 0) - page.height;
                        }
                    }
                }
                else {
                    // horizontal alignment
                    if (this.extension.helper.isLeftToRight()) {
                        // left to right
                        for (var i = 0; i < resources.length - 1; i++) {
                            page = resources[i];
                            nextPage = resources[i + 1];
                            nextPage.x = (page.x || 0) + page.width;
                        }
                    }
                    else {
                        // right to left
                        for (var i = resources.length - 1; i > 0; i--) {
                            page = resources[i];
                            nextPage = resources[i - 1];
                            nextPage.x = (page.x || 0) - page.width;
                        }
                    }
                }
            }
        }
        return resources;
    };
    OpenSeadragonCenterPanel.prototype.openPagesHandler = function () {
        var _this = this;
        this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.OPENSEADRAGON_OPEN);
        if (this.extension.helper.isMultiCanvas() &&
            !this.extension.helper.isContinuous()) {
            this.showPrevButton();
            this.showNextButton();
            $(".navigator").addClass("extraMargin");
            var viewingDirection = this.extension.helper.getViewingDirection() ||
                vocabulary_1.ViewingDirection.LEFT_TO_RIGHT;
            if (viewingDirection === vocabulary_1.ViewingDirection.RIGHT_TO_LEFT) {
                if (this.extension.helper.isFirstCanvas()) {
                    this.disableNextButton();
                }
                else {
                    this.enableNextButton();
                }
                if (this.extension.helper.isLastCanvas()) {
                    this.disablePrevButton();
                }
                else {
                    this.enablePrevButton();
                }
            }
            else {
                if (this.extension.helper.isFirstCanvas()) {
                    this.disablePrevButton();
                }
                else {
                    this.enablePrevButton();
                }
                if (this.extension.helper.isLastCanvas()) {
                    this.disableNextButton();
                }
                else {
                    this.enableNextButton();
                }
            }
        }
        this.setNavigatorVisible();
        // resize navigator for continuous manifests
        if (this.extension.helper.isContinuous()) {
            setTimeout(function () {
                _this.resizeNavigatorForContinuous();
            }, 200);
        }
        this.overlayAnnotations();
        this.updateBounds();
        // this only happens if prev/next search result were clicked and caused a reload
        if (this.navigatedFromSearch) {
            this.navigatedFromSearch = false;
            this.zoomToInitialAnnotation();
        }
        this.isFirstLoad = false;
        this.updateChoiceSwitchVisibility();
    };
    OpenSeadragonCenterPanel.prototype.resizeNavigatorForContinuous = function () {
        if (!this.viewer || !this.viewer.navigator)
            return;
        var homeBounds = this.viewer.world.getHomeBounds();
        var contentAspectRatio = homeBounds.width / homeBounds.height;
        var viewportWidth = this.$viewer.width();
        var viewportHeight = this.$viewer.height();
        var maxNavigatorWidth = 100;
        var maxNavigatorHeight = 100;
        var minVerticalNavigatorWidth = 60;
        var minHorizontalNavigatorHeight = 40;
        var navigatorWidth;
        var navigatorHeight;
        if (this.extension.helper.isVerticallyAligned()) {
            navigatorHeight = viewportHeight - this.$zoomInButton.height() - 4;
            navigatorWidth = navigatorHeight * contentAspectRatio;
            // Enforce max width
            if (navigatorWidth > maxNavigatorWidth) {
                navigatorWidth = maxNavigatorWidth;
            }
            // Enforce min width
            if (navigatorWidth < minVerticalNavigatorWidth) {
                navigatorWidth = minVerticalNavigatorWidth;
            }
        }
        else {
            navigatorWidth = viewportWidth;
            navigatorHeight = navigatorWidth / contentAspectRatio;
            // Enforce max height
            if (navigatorHeight > maxNavigatorHeight) {
                navigatorHeight = maxNavigatorHeight;
            }
            // Enforce min height
            if (navigatorHeight < minHorizontalNavigatorHeight) {
                navigatorHeight = minHorizontalNavigatorHeight;
            }
        }
        var navigatorElement = this.viewer.navigator.element;
        navigatorElement.style.width = "".concat(navigatorWidth, "px");
        navigatorElement.style.height = "".concat(navigatorHeight, "px");
        this.viewer.navigator.viewport.fitBounds(homeBounds, true);
        this.viewer.navigator.updateSize();
    };
    OpenSeadragonCenterPanel.prototype.zoomToInitialAnnotation = function () {
        var annotationRect = this.getInitialAnnotationRect();
        this.extension.previousAnnotationRect = null;
        this.extension.currentAnnotationRect = null;
        if (annotationRect && this.isZoomToSearchResultEnabled()) {
            this.zoomToAnnotation(annotationRect);
        }
    };
    OpenSeadragonCenterPanel.prototype.overlayAnnotations = function () {
        var _this = this;
        var annotations = this.getAnnotationsForCurrentImages();
        // clear existing annotations
        this.clearAnnotations();
        for (var i = 0; i < annotations.length; i++) {
            var annotation = annotations[i];
            var rects = this.getAnnotationOverlayRects(annotation);
            var _loop_1 = function (k) {
                var rect = rects[k];
                var div = document.createElement("DIV");
                div.id = "annotation-" + rect.canvasIndex + "-" + rect.resultIndex;
                div.title = (0, Utils_2.sanitize)(rect.chars);
                // if it's a pin
                if (rect.width === 1 && rect.height === 1) {
                    div.className = "annotationPin";
                    div.onclick = function (e) {
                        e.preventDefault();
                        _this.extensionHost.publish(IIIFEvents_1.IIIFEvents.PINPOINT_ANNOTATION_CLICKED, k);
                    };
                    var span = document.createElement("SPAN");
                    span.innerText = String(k + 1);
                    div.appendChild(span);
                }
                else {
                    // it's a rect
                    div.className = "annotationRect";
                }
                this_1.viewer.addOverlay(div, rect);
            };
            var this_1 = this;
            for (var k = 0; k < rects.length; k++) {
                _loop_1(k);
            }
        }
        if (annotations.length && this.shouldZoomToInitialAnnotation()) {
            this.zoomToInitialAnnotation();
        }
    };
    OpenSeadragonCenterPanel.prototype.updateBounds = function () {
        var settings = this.extension.getSettings();
        // if this is the first load and there are initial bounds, fit to those.
        if (this.isFirstLoad) {
            this.initialRotation = (this.extension.data).rotation;
            if (this.initialRotation) {
                this.viewer.viewport.setRotation(parseInt(this.initialRotation));
            }
            var xywh = this.extension.data.xywh;
            if (xywh) {
                this.initialBounds = XYWHFragment_1.XYWHFragment.fromString(xywh);
                this.currentBounds = this.initialBounds;
                this.fitToBounds(this.currentBounds);
            }
        }
        else if (settings.preserveViewport && this.currentBounds) {
            // if this isn't the first load and preserveViewport is enabled, fit to the current bounds.
            this.fitToBounds(this.currentBounds);
        }
        else {
            this.goHome();
        }
    };
    OpenSeadragonCenterPanel.prototype.goHome = function () {
        this.viewer.viewport.goHome(true);
    };
    OpenSeadragonCenterPanel.prototype.disablePrevButton = function () {
        this.prevButtonEnabled = false;
        this.$prevButton.addClass("disabled");
        this.$prevButton.attr("tabindex", -1);
    };
    OpenSeadragonCenterPanel.prototype.enablePrevButton = function () {
        this.prevButtonEnabled = true;
        this.$prevButton.removeClass("disabled");
        this.$prevButton.attr("tabindex", 0);
    };
    OpenSeadragonCenterPanel.prototype.hidePrevButton = function () {
        this.disablePrevButton();
        this.$prevButton.hide();
    };
    OpenSeadragonCenterPanel.prototype.showPrevButton = function () {
        this.enablePrevButton();
        this.$prevButton.show();
    };
    OpenSeadragonCenterPanel.prototype.disableNextButton = function () {
        this.nextButtonEnabled = false;
        this.$nextButton.addClass("disabled");
        this.$nextButton.attr("tabindex", -1);
    };
    OpenSeadragonCenterPanel.prototype.enableNextButton = function () {
        this.nextButtonEnabled = true;
        this.$nextButton.removeClass("disabled");
        this.$nextButton.attr("tabindex", 0);
    };
    OpenSeadragonCenterPanel.prototype.hideNextButton = function () {
        this.disableNextButton();
        this.$nextButton.hide();
    };
    OpenSeadragonCenterPanel.prototype.showNextButton = function () {
        this.enableNextButton();
        this.$nextButton.show();
    };
    OpenSeadragonCenterPanel.prototype.fitToBounds = function (bounds, immediate) {
        var _this = this;
        if (immediate === void 0) { immediate = true; }
        var rect = new openseadragon_1.default.Rect();
        rect.x = Number(bounds.x);
        rect.y = Number(bounds.y);
        rect.width = Number(bounds.w);
        rect.height = Number(bounds.h);
        setTimeout(function () {
            _this.viewer.viewport.fitBoundsWithConstraints(rect, immediate);
        }, 100);
    };
    OpenSeadragonCenterPanel.prototype.getCroppedImageBounds = function () {
        if (!this.viewer || !this.viewer.viewport)
            return null;
        var canvas = this.extension.helper.getCurrentCanvas();
        var dimensions = this.extension.getCroppedImageDimensions(canvas, this.viewer);
        if (dimensions) {
            var bounds = new XYWHFragment_1.XYWHFragment(dimensions.regionPos.x, dimensions.regionPos.y, dimensions.region.width, dimensions.region.height);
            return bounds.toString();
        }
        return null;
    };
    OpenSeadragonCenterPanel.prototype.getViewportBounds = function () {
        if (!this.viewer || !this.viewer.viewport)
            return null;
        var b = this.viewer.viewport.getBounds(true);
        var bounds = new XYWHFragment_1.XYWHFragment(Math.floor(b.x), Math.floor(b.y), Math.floor(b.width), Math.floor(b.height));
        return bounds;
    };
    OpenSeadragonCenterPanel.prototype.viewerResize = function (viewer) {
        if (!viewer.viewport)
            return;
        var center = viewer.viewport.getCenter(true);
        if (!center)
            return;
        // postpone pan for a millisecond - fixes iPad image stretching/squashing issue.
        setTimeout(function () {
            viewer.viewport.panTo(center, true);
        }, 1);
    };
    OpenSeadragonCenterPanel.prototype.clearAnnotations = function () {
        this.viewer.clearOverlays();
    };
    OpenSeadragonCenterPanel.prototype.getAnnotationsForCurrentImages = function () {
        var annotationsForCurrentImages = [];
        var annotations = this.extension.annotations;
        if (!annotations || !annotations.length)
            return annotationsForCurrentImages;
        var indices = this.extension.getPagedIndices();
        for (var i = 0; i < indices.length; i++) {
            var canvasIndex = indices[i];
            for (var j = 0; j < annotations.length; j++) {
                if (annotations[j].canvasIndex === canvasIndex) {
                    annotationsForCurrentImages.push(annotations[j]);
                    break;
                }
            }
        }
        return annotationsForCurrentImages;
    };
    OpenSeadragonCenterPanel.prototype.getAnnotationRectsForCurrentImages = function () {
        var annotations = this.getAnnotationsForCurrentImages();
        if (annotations.length) {
            return annotations
                .map(function (x) {
                return x.rects;
            })
                .reduce(function (a, b) {
                return a.concat(b);
            });
        }
        return [];
    };
    OpenSeadragonCenterPanel.prototype.updateVisibleAnnotationRects = function () {
        // after animating, loop through all search result rects and flag their visibility based on whether they are inside the current viewport.
        var annotationRects = this.getAnnotationRectsForCurrentImages();
        for (var i = 0; i < annotationRects.length; i++) {
            var rect = annotationRects[i];
            var viewportBounds = this.viewer.viewport.getBounds();
            rect.isVisible = Utils_1.Dimensions.hitRect(viewportBounds.x, viewportBounds.y, viewportBounds.width, viewportBounds.height, rect.viewportX, rect.viewportY);
        }
    };
    OpenSeadragonCenterPanel.prototype.getAnnotationRectIndex = function (annotationRect) {
        var annotationRects = this.getAnnotationRectsForCurrentImages();
        return annotationRects.indexOf(annotationRect);
    };
    OpenSeadragonCenterPanel.prototype.isZoomToSearchResultEnabled = function () {
        return Utils_1.Bools.getBool(this.extension.data.config.options.zoomToSearchResultEnabled, true);
    };
    OpenSeadragonCenterPanel.prototype.shouldZoomToInitialAnnotation = function () {
        return Utils_1.Bools.getBool(this.config.options.zoomToInitialAnnotation, true);
    };
    OpenSeadragonCenterPanel.prototype.prevAnnotation = function () {
        var annotationRects = this.getAnnotationRectsForCurrentImages();
        var currentAnnotationRect = this.extension.currentAnnotationRect;
        var currentAnnotationRectIndex = currentAnnotationRect
            ? this.getAnnotationRectIndex(currentAnnotationRect)
            : annotationRects.length;
        //const currentAnnotationRectIndex: number = this.getAnnotationRectIndex(<AnnotationRect>currentAnnotationRect);
        var foundRect = null;
        // if there's no currentAnnotationRect selected, index is the total available annotation rects for the current images.
        // minusing 1 makes the index the last of the available rects for the current images.
        for (var i = currentAnnotationRectIndex - 1; i >= 0; i--) {
            var rect = annotationRects[i];
            // this was removed as users found it confusing.
            // find the prev visible or non-visible rect.
            //if (rect.isVisible) {
            //    continue;
            //} else {
            foundRect = rect;
            break;
            //}
        }
        if (foundRect && this.isZoomToSearchResultEnabled()) {
            // if the rect's canvasIndex is less than the current canvasIndex
            if (foundRect.canvasIndex < this.extension.helper.canvasIndex) {
                this.extension.currentAnnotationRect =
                    foundRect;
                this.navigatedFromSearch = true;
                this.extensionHost.publish(IIIFEvents_1.IIIFEvents.ANNOTATION_CANVAS_CHANGE, [
                    foundRect,
                ]);
            }
            else {
                this.zoomToAnnotation(foundRect);
            }
        }
        else {
            this.navigatedFromSearch = true;
            this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.PREV_IMAGES_SEARCH_RESULT_UNAVAILABLE);
        }
    };
    OpenSeadragonCenterPanel.prototype.nextAnnotation = function () {
        var annotationRects = this.getAnnotationRectsForCurrentImages();
        var currentAnnotationRect = this.extension.currentAnnotationRect;
        var currentAnnotationRectIndex = currentAnnotationRect
            ? this.getAnnotationRectIndex(currentAnnotationRect)
            : -1;
        var foundRect = null;
        // if there's no currentAnnotationRect selected, index is -1.
        // adding 1 makes the index 0 of available rects for the current images.
        for (var i = currentAnnotationRectIndex + 1; i < annotationRects.length; i++) {
            var rect = annotationRects[i];
            // this was removed as users found it confusing.
            // find the next visible or non-visible rect.
            //if (rect.isVisible) {
            //    continue;
            //} else {
            foundRect = rect;
            break;
            //}
        }
        if (foundRect && this.isZoomToSearchResultEnabled()) {
            // if the rect's canvasIndex is greater than the current canvasIndex
            if (foundRect.canvasIndex > this.extension.helper.canvasIndex) {
                this.extension.currentAnnotationRect =
                    foundRect;
                this.navigatedFromSearch = true;
                this.extensionHost.publish(IIIFEvents_1.IIIFEvents.ANNOTATION_CANVAS_CHANGE, [
                    foundRect,
                ]);
            }
            else {
                this.zoomToAnnotation(foundRect);
            }
        }
        else {
            this.navigatedFromSearch = true;
            this.extensionHost.publish(Events_1.OpenSeadragonExtensionEvents.NEXT_IMAGES_SEARCH_RESULT_UNAVAILABLE);
        }
    };
    OpenSeadragonCenterPanel.prototype.getAnnotationRectByIndex = function (index) {
        var annotationRects = this.getAnnotationRectsForCurrentImages();
        if (!annotationRects.length)
            return null;
        return annotationRects[index];
    };
    OpenSeadragonCenterPanel.prototype.getInitialAnnotationRect = function () {
        var _this = this;
        var annotationRects = this.getAnnotationRectsForCurrentImages();
        if (!annotationRects.length)
            return null;
        // if we've got this far it means that a reload has happened
        // check if the lastCanvasIndex is greater or less than the current canvasIndex
        // if greater than, select the last annotation on the current page
        // if less than, select the first annotation on the current page
        // otherwise default to the first annotation
        var previousAnnotationRect = this.extension.previousAnnotationRect;
        if (!previousAnnotationRect) {
            if (this.extension.lastCanvasIndex > this.extension.helper.canvasIndex) {
                var result = annotationRects.filter(function (x) { return x.canvasIndex === _this.extension.helper.canvasIndex; });
                return result[result.length - 1];
            }
        }
        return annotationRects.filter(function (x) { return x.canvasIndex === _this.extension.helper.canvasIndex; })[0];
    };
    OpenSeadragonCenterPanel.prototype.zoomToAnnotation = function (annotationRect) {
        this.extension.previousAnnotationRect =
            this.extension.currentAnnotationRect ||
                annotationRect;
        this.extension.currentAnnotationRect =
            annotationRect;
        // if zoomToBoundsEnabled, zoom to the annotation's bounds.
        // otherwise, pan into view preserving the current zoom level.
        if (Utils_1.Bools.getBool(this.extension.data.config.options.zoomToBoundsEnabled, false)) {
            this.fitToBounds(new XYWHFragment_1.XYWHFragment(annotationRect.viewportX, annotationRect.viewportY, annotationRect.width, annotationRect.height), false);
        }
        else if (this.currentBounds) {
            var x = annotationRect.viewportX -
                (this.currentBounds.w * 0.5 - annotationRect.width * 0.5);
            var y = annotationRect.viewportY -
                (this.currentBounds.h * 0.5 - annotationRect.height * 0.5);
            var w = this.currentBounds.w;
            var h = this.currentBounds.h;
            var bounds = new XYWHFragment_1.XYWHFragment(x, y, w, h);
            this.fitToBounds(bounds);
        }
        this.highlightAnnotationRect(annotationRect);
        this.extensionHost.publish(IIIFEvents_1.IIIFEvents.ANNOTATION_CHANGE);
    };
    OpenSeadragonCenterPanel.prototype.highlightAnnotationRect = function (annotationRect) {
        var $rect = $("#annotation-" + annotationRect.canvasIndex + "-" + annotationRect.index);
        $rect.addClass("current");
        $(".annotationRect").not($rect).removeClass("current");
    };
    OpenSeadragonCenterPanel.prototype.getAnnotationOverlayRects = function (annotationGroup) {
        var newRects = [];
        if (!this.extension.resources) {
            return newRects;
        }
        var resource = this.extension.resources.filter(function (x) { return x.index === annotationGroup.canvasIndex; })[0];
        var index = this.extension.resources.indexOf(resource);
        var offsetX = 0;
        if (index > 0) {
            offsetX = (this.extension.resources[index - 1]).width;
        }
        for (var i = 0; i < annotationGroup.rects.length; i++) {
            var searchRect = annotationGroup.rects[i];
            var x = searchRect.x + offsetX + (index > 0 ? this.config.options.pageGap : 0);
            var y = searchRect.y;
            var w = searchRect.width;
            var h = searchRect.height;
            var rect = new openseadragon_1.default.Rect(x, y, w, h);
            searchRect.viewportX = x;
            searchRect.viewportY = y;
            rect.canvasIndex = searchRect.canvasIndex;
            rect.resultIndex = searchRect.index;
            rect.chars = searchRect.chars;
            newRects.push(rect);
        }
        return newRects;
    };
    OpenSeadragonCenterPanel.prototype.resize = function () {
        var _this = this;
        _super.prototype.resize.call(this);
        this.$viewer.height(this.$content.height() - this.$viewer.verticalMargins());
        this.$viewer.width(this.$content.width() - this.$viewer.horizontalMargins());
        if (!this.isCreated)
            return;
        if (this.title) {
            this.$title.text((0, Utils_2.sanitize)(this.title));
        }
        this.$spinner.css("top", this.$content.height() / 2 - this.$spinner.height() / 2);
        this.$spinner.css("left", this.$content.width() / 2 - this.$spinner.width() / 2);
        var viewingDirection = this.extension.helper.getViewingDirection() ||
            vocabulary_1.ViewingDirection.LEFT_TO_RIGHT;
        if (this.extension.helper.isRightToLeft()) {
            this.$title.addClass("rtl");
        }
        else {
            this.$title.removeClass("rtl");
        }
        if (this.extension.helper.isMultiCanvas() &&
            this.$prevButton &&
            this.$nextButton) {
            var verticalButtonPos = Math.floor(this.$content.width() / 2);
            switch (viewingDirection) {
                case vocabulary_1.ViewingDirection.BOTTOM_TO_TOP:
                    this.$prevButton.addClass("down");
                    this.$nextButton.addClass("up");
                    this.$prevButton.css("left", verticalButtonPos - this.$prevButton.outerWidth() / 2);
                    this.$prevButton.css("top", this.$content.height() - this.$prevButton.height());
                    this.$nextButton.css("left", verticalButtonPos * -1 - this.$nextButton.outerWidth() / 2);
                    break;
                case vocabulary_1.ViewingDirection.TOP_TO_BOTTOM:
                    this.$prevButton.css("left", verticalButtonPos - this.$prevButton.outerWidth() / 2);
                    this.$nextButton.css("left", verticalButtonPos * -1 - this.$nextButton.outerWidth() / 2);
                    this.$nextButton.css("top", this.$content.height() - this.$nextButton.height());
                    break;
                default:
                    this.$prevButton.css("top", (this.$content.height() - this.$prevButton.height()) / 2);
                    this.$nextButton.css("top", (this.$content.height() - this.$nextButton.height()) / 2);
                    break;
            }
            // resize navigator for continuous manifests
            if (this.extension.helper.isContinuous()) {
                setTimeout(function () {
                    _this.resizeNavigatorForContinuous();
                }, 200);
            }
        }
    };
    OpenSeadragonCenterPanel.prototype.setFocus = function () {
        if (this.$canvas && !this.$canvas.is(":focus")) {
            if (this.extension.data.config.options.allowStealFocus) {
                this.$canvas.focus();
            }
        }
    };
    OpenSeadragonCenterPanel.prototype.setNavigatorVisible = function () {
        var navigatorEnabled = Utils_1.Bools.getBool(this.extension.getSettings().navigatorEnabled, true) &&
            this.extension.isDesktopMetric();
        if (this.viewer && this.viewer.navigator) {
            this.viewer.navigator.setVisible(navigatorEnabled);
            if (navigatorEnabled) {
                this.$navigator.show();
            }
            else {
                this.$navigator.hide();
            }
        }
    };
    OpenSeadragonCenterPanel.prototype.getControlsFadeLength = function () {
        return this.extension.getSettings().reducedAnimation
            ? 0
            : this.config.options.controlsFadeLength || 250;
    };
    OpenSeadragonCenterPanel.prototype.indicesIncludeChoices = function (indices) {
        var _this = this;
        return indices.some(function (index) {
            var canvas = _this.extension.helper.getCanvasByIndex(index);
            return canvas.getChoices().length > 0;
        });
    };
    OpenSeadragonCenterPanel.prototype.updateChoiceSwitchVisibility = function () {
        if (!this.$choiceSwitchButton)
            return;
        var indices = this.extension.getPagedIndices();
        var hasChoices = this.indicesIncludeChoices(indices);
        this.$choiceSwitchButton.css("visibility", hasChoices ? "visible" : "hidden");
    };
    return OpenSeadragonCenterPanel;
}(CenterPanel_1.CenterPanel));
exports.OpenSeadragonCenterPanel = OpenSeadragonCenterPanel;
//# sourceMappingURL=OpenSeadragonCenterPanel.js.map