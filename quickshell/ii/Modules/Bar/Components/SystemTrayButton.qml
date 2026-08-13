import QtQuick
import qs.Core

BarButton {
    icon: widget && widget.isOpen ? "chevron-up" : "chevron-down"
}
