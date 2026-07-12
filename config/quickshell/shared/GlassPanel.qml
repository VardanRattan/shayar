import QtQuick
import QtQuick.Effects

Item {
    id: glass

    property var colors
    property var tokens
    property alias radius: panelBg.radius

    Rectangle {
        id: panelBg
        anchors.fill: parent
        radius: glass.tokens ? glass.tokens.panel_radius : 24
        color: glass.colors && glass.tokens
            ? Qt.rgba(glass.colors.surface_container.r, glass.colors.surface_container.g, glass.colors.surface_container.b, glass.tokens.panel_bg_alpha)
            : "transparent"

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: glass.tokens ? glass.tokens.blur_strength : 0.7
            saturation: 0.0
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: glass.colors && glass.tokens
                        ? Qt.rgba(glass.colors.primary.r, glass.colors.primary.g, glass.colors.primary.b, glass.tokens.gradient_top_alpha)
                        : "transparent"
                }
                GradientStop {
                    position: 0.3
                    color: glass.colors && glass.tokens
                        ? Qt.rgba(glass.colors.primary.r, glass.colors.primary.g, glass.colors.primary.b, glass.tokens.gradient_mid_alpha)
                        : "transparent"
                }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            border.color: glass.colors && glass.tokens
                ? Qt.rgba(glass.colors.primary.r, glass.colors.primary.g, glass.colors.primary.b, glass.tokens.border_alpha)
                : "transparent"
            border.width: glass.tokens ? glass.tokens.border_width : 1
        }
    }

    RectangularShadow {
        anchors.fill: panelBg
        radius: panelBg.radius
        blur: 24
        color: glass.colors && glass.tokens
            ? Qt.rgba(glass.colors.shadow.r, glass.colors.shadow.g, glass.colors.shadow.b, glass.tokens.shadow_alpha)
            : "transparent"
    }
}
