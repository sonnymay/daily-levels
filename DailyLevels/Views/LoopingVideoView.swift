//
//  LoopingVideoView.swift
//  Daily Levels
//
//  A seamless looping video player using only AVFoundation (no third-party deps).
//  Drop `grind_loop.mp4` / `sleep_loop.mp4` into the app target and HeroScenePanel
//  plays them automatically. This is the wiring for the Kling loop clips.
//
//  Swift note: `UIViewRepresentable` is the bridge that lets a UIKit view appear inside
//  SwiftUI — React analogy: a thin wrapper component around a non-React DOM widget.
//

import SwiftUI
import AVFoundation

struct LoopingVideoView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        LoopingPlayerUIView(url: url)
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        uiView.setURL(url)
    }
}

/// Backed by an AVPlayerLayer; uses AVPlayerLooper for gapless looping. Muted, fills the frame.
final class LoopingPlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    private let queuePlayer = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    init(url: URL) {
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
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        queuePlayer.play()
    }
}
