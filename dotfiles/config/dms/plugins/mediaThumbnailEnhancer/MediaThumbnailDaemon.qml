import QtQuick
import qs.Common
import qs.Services

QtObject {
    id: root

    property string pluginId: "mediaThumbnailEnhancer"
    property var pluginService: null
    property var popoutService: null

    property string _lastResolvedKey: ""
    property string _lastEnhancedArt: ""
    property string _lastEnhancedTitle: ""
    property string _lastEnhancedArtist: ""
    property bool _resolving: false

    readonly property string braveLogoSha1: "1a0e138f1c6817d0b68f43d4ff3f8ba64b2ce001"
    readonly property string chromeLogoSha1: "764a730860c5b8a7bbee690ee5a443672ae37dc8"

    function isPlaceholderArt(url) {
        if (!url || url === "")
            return true;
        if (url.indexOf(braveLogoSha1) !== -1 || url.indexOf(chromeLogoSha1) !== -1)
            return true;
        return false;
    }

    function needsMetadataClean(title, artist) {
        if (!title)
            return false;
        if (!artist || artist === "")
            return true;
        if (title.indexOf("▶") !== -1 || title.indexOf(" | ") !== -1)
            return true;
        return false;
    }

    function checkAndEnhance() {
        const player = MprisController.activePlayer;
        if (!player)
            return;

        const rawTitle = player.trackTitle || MprisController.stableTitle || "";
        const rawArtist = player.trackArtist || "";
        const rawAlbum = player.trackAlbum || "";
        if (!rawTitle && !rawArtist)
            return;

        const currentArt = TrackArtService.resolvedArtUrl || "";
        const key = rawTitle + "::" + rawArtist;

        // If we already resolved this exact track, keep its enhanced art/metadata applied
        if (key === _lastResolvedKey && _lastEnhancedArt !== "") {
            if (isPlaceholderArt(currentArt) && currentArt !== _lastEnhancedArt) {
                TrackArtService.resolvedArtUrl = _lastEnhancedArt;
            }
            if (_lastEnhancedTitle !== "" && MprisController.stableTitle !== _lastEnhancedTitle) {
                MprisController.stableTitle = _lastEnhancedTitle;
            }
            if (_lastEnhancedArtist !== "" && (!MprisController.stableArtist || MprisController.stableArtist === "")) {
                MprisController.stableArtist = _lastEnhancedArtist;
            }
            return;
        }

        if (!isPlaceholderArt(currentArt) && !needsMetadataClean(rawTitle, rawArtist))
            return;

        if (_resolving && key === _lastResolvedKey)
            return;

        _resolving = true;
        _lastResolvedKey = key;

        Proc.runCommand(
            "mediaThumb.resolve",
            ["__HOME__/.local/bin/fetch-media-thumbnail", rawTitle, rawArtist, rawAlbum, currentArt],
            (stdout, exitCode) => {
                root._resolving = false;
                if (exitCode !== 0 || !stdout)
                    return;
                try {
                    const data = JSON.parse(stdout.trim());
                    if (data.artUrl) {
                        root._lastEnhancedArt = data.artUrl;
                        if (root.isPlaceholderArt(TrackArtService.resolvedArtUrl)) {
                            TrackArtService.resolvedArtUrl = data.artUrl;
                        }
                    }
                    if (data.title) {
                        root._lastEnhancedTitle = data.title;
                        MprisController.stableTitle = data.title;
                    }
                    if (data.artist) {
                        root._lastEnhancedArtist = data.artist;
                        if (!player.trackArtist || player.trackArtist === "") {
                            MprisController.stableArtist = data.artist;
                        }
                    }
                } catch (e) {}
            },
            100,
            10000
        );
    }

    property Connections mprisConn: Connections {
        target: MprisController
        function onActivePlayerChanged() {
            enhanceTimer.restart();
        }
        function onStableTitleChanged() {
            enhanceTimer.restart();
        }
        function onStableArtistChanged() {
            enhanceTimer.restart();
        }
    }

    property Connections artConn: Connections {
        target: TrackArtService
        function onResolvedArtUrlChanged() {
            if (root.isPlaceholderArt(TrackArtService.resolvedArtUrl)) {
                enhanceTimer.restart();
            }
        }
    }

    property Timer enhanceTimer: Timer {
        interval: 250
        repeat: false
        onTriggered: root.checkAndEnhance()
    }

    property Timer periodicGuard: Timer {
        interval: 2500
        repeat: true
        running: true
        onTriggered: root.checkAndEnhance()
    }

    Component.onCompleted: {
        try {
            if (TrackArtService._artHashDenylist && TrackArtService._artHashDenylist.indexOf(braveLogoSha1) === -1) {
                TrackArtService._artHashDenylist.push(braveLogoSha1);
            }
        } catch (e) {}
        enhanceTimer.restart();
    }
}
