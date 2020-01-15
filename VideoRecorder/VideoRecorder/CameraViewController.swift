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

    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!

    private var bestCamera: AVCaptureDevice {
        if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            return device
        }
        // fallback camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }

        fatalError("No cameras on the device, or you are running on the simulator (not supported)")
    }

    // MARK: - View Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		// Resize camera preview to fill the entire screen
		cameraView.videoPlayerView.videoGravity = .resizeAspectFill
        setUpCamera()
	}

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }

    @IBAction func recordButtonPressed(_ sender: Any) {
        recordButton.isSelected.toggle()
	}

    // MARK: - Helper Methods

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
        //  - audio input
        //  - video output (movie)

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

