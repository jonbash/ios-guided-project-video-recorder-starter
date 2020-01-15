//
//  CameraViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    private lazy var captureSession = AVCaptureSession()
    private lazy var fileOutput = AVCaptureMovieFileOutput()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!

    private var bestCamera: AVCaptureDevice {
        if let device = AVCaptureDevice.default(
            .builtInUltraWideCamera,
            for: .video,
            position: .back)
        {
            return device
        }
        // fallback camera
        if let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back)
        {
            return device
        }

        fatalError("No cameras on the device, or you are running on the simulator (not supported)")
    }
    private var bestAudio: AVCaptureDevice {
        if let device = AVCaptureDevice.default(for: .audio) {
            return device
        }
        fatalError("mic is borked!")
    }

    // MARK: - View Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		// Resize camera preview to fill the entire screen
		cameraView.videoPlayerView.videoGravity = .resizeAspectFill

        setUpCamera()

        // add tap gesture to replay video (repeat loop?)
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(viewTapped(_:)))
        view.addGestureRecognizer(tapGesture)
	}

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }

    // MARK: - Actions

    @objc
    private func viewTapped(_ tapGesture: UITapGestureRecognizer) {
        if tapGesture.state == .ended {
            print("tap")
            playMovie()
        }
    }

    @IBAction
    private func recordButtonPressed(_ sender: Any) {
        toggleRecording()
	}

    // MARK: - Helper Methods

    func toggleRecording() {
        if fileOutput.isRecording {
            fileOutput.stopRecording()
        } else {
            fileOutput.startRecording(
                to: newRecordingURL(),
                recordingDelegate: self)
        }
    }

    func playMovie(url: URL) {
        player = AVPlayer(url: url)
        
        playerLayer = AVPlayerLayer(player: player)

        // TODO: customize rectangle bounds
        playerLayer?.frame = view.bounds
        var topRect = view.bounds
        topRect.size.height /= 4
        topRect.size.width /= 4
        topRect.origin.y = view.layoutMargins.top
        playerLayer?.frame = topRect

        view.layer.addSublayer(playerLayer!)
        player?.play()
        // TODO: add delegate and repeat video at end
    }

    func playMovie() {
        player?.seek(to: .zero)
        player?.play()
    }

    private func updateViews() {
        recordButton.isSelected = fileOutput.isRecording
    }

    private func setUpCamera() {
        // get the best camera
        let camera = bestCamera

        captureSession.beginConfiguration()

        // make changes to the devices connected

        //  - video input
        guard
            let cameraInput = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(cameraInput)
            else { fatalError("Camera is borked?") }
        captureSession.addInput(cameraInput)

        let sessionPreset: AVCaptureSession.Preset = .hd1920x1080
        if captureSession.canSetSessionPreset(sessionPreset) {
            captureSession.sessionPreset = sessionPreset
        }
        // - audio input
        let mic = bestAudio
        guard
            let audioInput = try? AVCaptureDeviceInput(device: mic),
            captureSession.canAddInput(audioInput)
            else {
                fatalError("can't add mic device!")
        }
        captureSession.addInput(audioInput)

        // - video output (movie recording)
        guard captureSession.canAddOutput(fileOutput) else {
            fatalError("can't set up the file output for movie")
        }
        captureSession.addOutput(fileOutput)

        captureSession.commitConfiguration()
        cameraView.session = captureSession
    }
	
	/// Creates a new file URL in the documents directory
	private func newRecordingURL() -> URL {
		let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask)
            .first!

		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]

		let name = formatter.string(from: Date())
		let fileURL = documentsDirectory
            .appendingPathComponent(name)
            .appendingPathExtension("mov")
		return fileURL
	}
}

// MARK: - Recording Delegate

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        updateViews()
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error = error {
            print("Error with video recording: \(error)")
        }
        print("finished recording video: \(outputFileURL.path)")
        updateViews()
        playMovie(url: outputFileURL)
    }
}
