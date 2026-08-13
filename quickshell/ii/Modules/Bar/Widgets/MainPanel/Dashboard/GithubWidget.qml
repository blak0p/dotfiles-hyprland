import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.services

Card {
    id: root

    property string username: GithubService.username
    property string avatarUrl: GithubService.avatarUrl
    property string fullName: GithubService.fullName
    property string bio: GithubService.bio
    property string location: GithubService.location
    property int publicRepos: GithubService.publicRepos
    property int privateRepos: GithubService.privateRepos
    property int followers: GithubService.followers
    property int totalStars: GithubService.totalStars
    property int totalForks: GithubService.totalForks
    property string topRepoName: GithubService.topRepoName
    property string topRepoDesc: GithubService.topRepoDesc
    property int topRepoStars: GithubService.topRepoStars
    property int topRepoForks: GithubService.topRepoForks
    property string topRepoLang: GithubService.topRepoLang
    property string joinedDate: GithubService.joinedDate
    property int totalCommits: GithubService.totalCommits
    property string topLanguage: GithubService.topLanguage

    clip: true

    ColumnLayout {
        id: profileLayout

        anchors.fill: parent
        spacing: Constants.sizeXs
        visible: root.username !== ""

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd

            TapHandler {
                onTapped: Qt.openUrlExternally("https://github.com/" + root.username)
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            Item {
                id: avatarWrapper

                width: 54
                height: 54
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: gradientRing

                    anchors.fill: parent
                    radius: width / 2
                    scale: avatarHover.hovered ? 1.06 : 1

                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Theme.accent
                        }

                        GradientStop {
                            position: 1
                            color: Theme.accentComplementary
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutQuad
                        }

                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 800
                        loops: Animation.Infinite
                        running: GithubService.isFetching
                        onRunningChanged: {
                            if (!running)
                                gradientRing.rotation = 0;

                        }
                    }

                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 50
                    height: 50
                    radius: width / 2
                    color: Theme.bg
                }

                Item {
                    id: avatarContainer

                    anchors.centerIn: parent
                    width: 44
                    height: 44

                    Image {
                        id: userImage

                        anchors.fill: parent
                        source: (root.avatarUrl || root.username) ? (root.avatarUrl || "https://github.com/identicons/" + root.username + ".png") : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(88, 88)
                        mipmap: true
                        visible: false
                        antialiasing: true
                    }

                    Rectangle {
                        id: mask

                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                        antialiasing: true
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: userImage
                        maskSource: mask
                        visible: userImage.status === Image.Ready
                    }

                }

                HoverHandler {
                    id: avatarHover
                }

            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                ThemedText {
                    text: root.fullName || root.username
                    font.pixelSize: Constants.sizeMd
                    font.bold: true
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                ThemedText {
                    text: "@" + root.username
                    font.pixelSize: Constants.sizeSm
                    color: Theme.muted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

            }

        }

        ThemedText {
            visible: root.bio !== ""
            text: root.bio
            color: Theme.fg
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            maximumLineCount: 2
            elide: Text.ElideRight

            font {
                italic: true
                pixelSize: Constants.sizeSm
            }

        }

        Divider {
        }

        ColumnLayout {
            id: statsLayout

            Layout.fillWidth: true
            spacing: Constants.sizeXs

            InfoRow {
                visible: GithubService.hasToken
                icon: "commit"
                label: Translation.tr("Total Commits")
                value: String(root.totalCommits)
            }

            InfoRow {
                icon: "star"
                label: Translation.tr("Total Stars")
                value: String(root.totalStars)
            }

            InfoRow {
                icon: "code"
                label: Translation.tr("Repositories")
                value: String(root.publicRepos + (GithubService.hasToken ? root.privateRepos : 0))
            }

            InfoRow {
                icon: "fork"
                label: Translation.tr("Total Forks")
                value: String(root.totalForks)
            }

        }

        Card {
            Layout.fillWidth: true
            backgroundColor: Theme.bgSecondary
            contentPadding: Constants.sizeMd
            visible: root.topRepoName !== "..." && root.topRepoName !== "None"
            scale: repoHover.hovered ? 1.02 : 1
            radius: Constants.sizeSm
            useBorder: false

            TapHandler {
                onTapped: Qt.openUrlExternally("https://github.com/" + root.username + "/" + root.topRepoName)
            }

            HoverHandler {
                id: repoHover

                cursorShape: Qt.PointingHandCursor
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Constants.sizeXs

                    SvgIcon {
                        icon: "star-filled"
                        flat: true
                        iconColor: Theme.accent
                        iconSize: Constants.sizeSm + 2
                    }

                    ThemedText {
                        text: root.topRepoName.replace(/^.*\//, "")
                        font.pixelSize: Constants.sizeSm
                        font.bold: true
                        color: Theme.fg
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                }

                ThemedText {
                    visible: root.topRepoDesc !== ""
                    text: root.topRepoDesc
                    font.pixelSize: Constants.sizeXs + 2
                    color: Theme.muted
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: Constants.sizeMd

                    RowLayout {
                        spacing: 4
                        visible: root.topRepoLang !== ""

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.accent
                        }

                        ThemedText {
                            text: root.topRepoLang
                            font.pixelSize: Constants.sizeXs + 2
                            color: Theme.muted
                        }

                    }

                    RowLayout {
                        spacing: 4
                        visible: root.topRepoStars > 0

                        SvgIcon {
                            icon: "star"
                            flat: true
                            iconColor: Theme.accent
                            iconSize: Constants.sizeXs + 2
                        }

                        ThemedText {
                            text: String(root.topRepoStars)
                            font.pixelSize: Constants.sizeXs + 2
                            color: Theme.muted
                        }

                    }

                    RowLayout {
                        spacing: 4
                        visible: root.topRepoForks > 0

                        SvgIcon {
                            icon: "fork"
                            flat: true
                            iconColor: Theme.accent
                            iconSize: Constants.sizeXs + 2
                        }

                        ThemedText {
                            text: String(root.topRepoForks)
                            font.pixelSize: Constants.sizeXs + 2
                            color: Theme.muted
                        }

                    }

                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: Constants.animFast
                    easing.type: Easing.OutQuad
                }

            }

        }

    }

    ColumnLayout {
        id: errorLayout

        anchors.fill: parent
        anchors.margins: Constants.sizeLg
        visible: root.username === ""
        spacing: Constants.sizeSm

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 64
            height: 64
            radius: width / 2
            color: Theme.bgSecondary

            SvgIcon {
                anchors.centerIn: parent
                icon: "github"
                iconSize: Constants.size4Xl
                flat: true
                iconColor: Theme.accent
            }

        }

        Item {
            Layout.preferredHeight: Constants.sizeXs
        }

        ThemedText {
            text: Translation.tr("Username Required")
            color: Theme.fg
            font.pixelSize: Constants.sizeMd
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        ThemedText {
            text: Translation.tr("Configure your GitHub username in settings to view your statistics.")
            color: Theme.muted
            font.pixelSize: Constants.sizeSm
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }

        Item {
            Layout.preferredHeight: Constants.sizeXs
        }

        ThemedButton {
            text: Translation.tr("Configure")
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                AppState.pendingSettingsTab = 4;
                AppState.openPopup("minflair_settings");
            }
        }

        Item {
            Layout.fillHeight: true
        }

    }

}
