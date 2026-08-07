"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = toggleExpandTextByLines;
var Utils_1 = require("../../Utils");
function switchClass(element, class1, class2) {
    return element.each(function () {
        $(this).removeClass(class1).addClass(class2);
    });
}
function removeLastWord(element, chars, depth) {
    if (chars === void 0) { chars = 8; }
    if (depth === void 0) { depth = 0; }
    return element.each(function () {
        var $self = $(this);
        if ($self.contents().length > 0) {
            var $lastElement = $self.contents().last();
            if ($lastElement[0].nodeType === 3) {
                var words = $lastElement.text().trim().split(" ");
                if (words.length > 1) {
                    words.splice(words.length - 1, 1);
                    $lastElement[0].data = words.join(" "); // textnode.data
                    return;
                }
                else if ("undefined" !== typeof chars &&
                    words.length === 1 &&
                    words[0].length > chars) {
                    $lastElement[0].data = words.join(" ").substring(0, chars);
                    return;
                }
            }
            removeLastWord($lastElement, chars, depth + 1); // Element
        }
        else if (depth > 0) {
            // Empty element
            $self.remove();
        }
    });
}
function toggleExpandTextByLines(items, lines, lessText, moreText, cb, lessAriaLabelTemplate, moreAriaLabelTemplate) {
    if (lessAriaLabelTemplate === void 0) { lessAriaLabelTemplate = "Less information: Hide {0}"; }
    if (moreAriaLabelTemplate === void 0) { moreAriaLabelTemplate = "More information: Reveal {0}"; }
    return items.each(function () {
        var $self = $(this);
        var $label = $self.find(".label");
        var $values = $self.find(".value");
        $values.each(function (i, value) {
            var $value = $(value);
            var expandedText = $value.html();
            var labelText = $label
                .contents()
                .filter(function () {
                return this.nodeType === Node.TEXT_NODE;
            })
                .text()
                .trim();
            // add 'pad' to account for the right margin in the sidebar
            var $buttonPad = $('<span>&hellip; <a href="#" class="toggle more">morepad</a></span>');
            // when height changes, store string, then pick from line counts
            var stringsByLine = [expandedText];
            var lastHeight = $self.height();
            // Until empty
            while ($value.text().length > 0) {
                removeLastWord($value);
                var html = $value.html();
                $value.append($buttonPad);
                var valueHeight = $value.height();
                if (valueHeight !== undefined &&
                    lastHeight !== undefined &&
                    lastHeight > valueHeight) {
                    stringsByLine.unshift(html);
                    lastHeight = $value.height();
                }
                $buttonPad.remove();
            }
            if (stringsByLine.length <= lines) {
                $value.html(expandedText);
                return;
            }
            var collapsedText = stringsByLine[lines - 1];
            // Toggle function
            var expanded = false;
            $value.toggle = function () {
                $value.empty();
                var $toggleButton = $('<a href="#" class="toggle"></a>');
                if (expanded) {
                    var lessAriaLabel = Utils_1.Strings.format(lessAriaLabelTemplate, labelText);
                    $value.html(expandedText + " ");
                    $toggleButton.text(lessText);
                    switchClass($toggleButton, "less", "more");
                    $toggleButton.attr("aria-label", lessAriaLabel);
                }
                else {
                    var moreAriaLabel = Utils_1.Strings.format(moreAriaLabelTemplate, labelText);
                    $value.html(collapsedText + "&hellip; ");
                    $toggleButton.text(moreText);
                    switchClass($toggleButton, "more", "less");
                    $toggleButton.attr("aria-label", moreAriaLabel);
                }
                $toggleButton.one("click", function (e) {
                    e.preventDefault();
                    $value.toggle();
                });
                expanded = !expanded;
                $value.append($toggleButton);
                if (cb)
                    cb();
            };
            $value.toggle();
        });
    });
}
//# sourceMappingURL=toggleExpandTextByLines.js.map