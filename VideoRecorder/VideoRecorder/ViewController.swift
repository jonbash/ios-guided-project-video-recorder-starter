//
//  ViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		getPermissionAndShowCamera()
	}
	
	private func showCamera() {
		performSegue(withIdentifier: "ShowCamera", sender: self)
	}

    private func getPermissionAndShowCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        // skipping over edge cases where things can fail
        switch status {
        case .notDetermined:
            // first time user - they haven't seen the dialog to give permission
            requestPermission()
        case .restricted:
            // Parental controls disabled camera
            fatalError("Video is disabled for the user (parental controls)")
            // TODO: add UI to inform the user
        case .denied:
            // user did not give us access (maybe it was an accident)
            fatalError("User denied access to camera")
            // TODO: add UI to inform the user
        case .authorized:
            // we asked for permission (2nd time they've used app)
            showCamera()
        @unknown default:
            fatalError("A new auth status was added that we need to handle")
        }
    }

    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { permissionGranted in
            guard permissionGranted else {
                fatalError("User denied access to camera")
                // TODO: add UI to inform the user
            }
            DispatchQueue.main.async { [weak self] in
                self?.showCamera()
            }
        }
    }
}
