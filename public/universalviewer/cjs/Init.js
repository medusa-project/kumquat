"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.init = void 0;
var Events_1 = require("./Events");
var UniversalViewer_1 = require("./UniversalViewer");
var init = function (el, data) {
    console.log("[UV Init] fullscreen-exit fix v5 loaded - 2026-06-01");
    var uv;
    var isFullScreen = false;
    var overrideFullScreen = false;
    var isProcessingFullscreenExit = false;
    var container = typeof el === "string" ? document.getElementById(el) : el;
    if (!container) {
        throw new Error("UV target element not found");
    }
    container.innerHTML = "";
    var parent = document.createElement("div");
    container.appendChild(parent);
    // extra div is needed for safari full screen
    var uvDiv = document.createElement("div");
    parent.appendChild(uvDiv);
    var resize = function () {
        if (uv) {
            if (isFullScreen && !overrideFullScreen) {
                // is full screen and not overridden.
                parent.style.width = window.innerWidth + "px";
                parent.style.height = window.innerHeight + "px";
            }
            else {
                // either we're not full screen or scaling to the window size is overridden
                parent.style.width = container.offsetWidth + "px";
                parent.style.height = container.offsetHeight + "px";
            }
            uv.resize();
        }
    };
    window.addEventListener("resize", function () {
        resize();
    });
    window.addEventListener("orientationchange", function () {
        setTimeout(function () {
            resize();
        }, 100);
    });
    uv = new UniversalViewer_1.UniversalViewer({
        target: uvDiv,
        data: data,
    });
    // todo: can we remove the following two event listeners
    // by using css to scale the parent div?
    uv.on(Events_1.Events.CREATED, function (_obj) {
        resize();
    }, false);
    uv.on(Events_1.Events.EXTERNAL_RESOURCE_OPENED, function (_obj) {
        setTimeout(function () {
            resize();
        }, 100);
    }, false);
    uv.on(Events_1.Events.TOGGLE_FULLSCREEN, function (data) {
        if (!isProcessingFullscreenExit) {
            isFullScreen = data.isFullScreen;
            overrideFullScreen = data.overrideFullScreen;
        }
        if (!data.overrideFullScreen) {
            if (isFullScreen) {
                var requestFullScreen = getRequestFullScreen(parent);
                if (requestFullScreen) {
                    requestFullScreen.call(parent);
                    // resize();
                }
            }
            else {
              if (!isProcessingFullscreenExit && document.fullscreenElement) {
                var exitFullScreen = getExitFullScreen();
                if (exitFullScreen) {
                  const result = exitFullScreen.call(document);
                  if (result && typeof result.catch === "function") {
                    result.catch(() => { });
                  } 
                }
              }  
            }
        }
        setTimeout(function () {
            resize();
        }, 100);
    }, false);
    uv.on(Events_1.Events.ERROR, function (message) {
        console.error(message);
    }, false);
    function fullScreenChange(e) {
      const isNowFullscreen = !!document.fullscreenElement;

      if (!isNowFullscreen && isFullScreen && !isProcessingFullscreenExit) {
        isProcessingFullscreenExit = true;
        isFullScreen = false;

        setTimeout(function () {
          if (uv && typeof uv.exitFullScreen === "function") {
            try {
              uv.exitFullScreen();
            } catch (err) {}
          }
        }, 0);

        setTimeout(function () {
          resize();
          window.dispatchEvent(new Event("resize"));
          isProcessingFullscreenExit = false;
        }, 50);
      }
    }
    document.addEventListener("fullscreenchange", fullScreenChange, false);
    document.addEventListener("webkitfullscreenchange", fullScreenChange, false);
    document.addEventListener("MSFullscreenChange", fullScreenChange, false);
    return uv;
};
exports.init = init;
function getRequestFullScreen(elem) {
  if (elem.requestFullscreen) return elem.requestFullscreen;
  if (elem.webkitRequestFullscreen) return elem.webkitRequestFullscreen;
  if (elem.msRequestFullscreen) return elem.msRequestFullscreen;
  return null;
}

function getExitFullScreen() {
  if (document.exitFullscreen) return document.exitFullscreen;
  if (document.webkitExitFullscreen) return document.webkitExitFullscreen;
  if (document.msExitFullscreen) return document.msExitFullscreen;
  return null;
}

//# sourceMappingURL=Init.js.map