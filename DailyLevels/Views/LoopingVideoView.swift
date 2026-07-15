//
//  LoopingVideoView.swift
//  Daily Levels
//
//  A seamless looping video player using only AVFoundation (no third-party deps).
//  HeroScenePanel supplies the current class's bundled `<class>_grind.mp4` clip.
//  Paused heroes use still `<class>_sleep.png` artwork instead of this player.
//
//  Swift note: `UIViewRepresentable` is the bridge that lets a UIKit view appear inside
//  SwiftUI — React analogy: a thin wrapper component around a non-React DOM widget.
//

import SwiftUI
import AVFoundation

struct LoopingVideoView: UIViewRepresentable {
    let url: URL
    var isPlaying = true

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        LoopingPlayerUIView(url: url, isPlaying: isPlaying)
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        uiView.setURL(url)
        uiView.setPlaying(isPlaying)
    }
}

/// Backed by an AVPlayerLayer; uses AVPlayerLooper for gapless looping. Muted, fills the frame.
final class LoopingPlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    private let queuePlayer = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private var currentURL: URL?
    private var isPlaying: Bool

    init(url: URL, isPlaying: Bool) {
        self.isPlaying = isPlaying
        super.init(frame: .zero)
        queuePlayer.isMuted = true
        playerLayer.player = queuePlayer
        playerLayer.videoGravity = .resizeAspectFill
        setURL(url)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    func setURL(_ url: URL) {
        guard url != currentURL else { return }
        currentURL = url
        looper?.disableLooping()
        looper = nil
        queuePlayer.removeAllItems()
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        if isPlaying { queuePlayer.play() }
    }

    func setPlaying(_ shouldPlay: Bool) {
        guard shouldPlay != isPlaying else { return }
        isPlaying = shouldPlay
        if shouldPlay {
            queuePlayer.play()
        } else {
            queuePlayer.pause()
        }
    }

    deinit {
        looper?.disableLooping()
        queuePlayer.pause()
        queuePlayer.removeAllItems()
    }
}
