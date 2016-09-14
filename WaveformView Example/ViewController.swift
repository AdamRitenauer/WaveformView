//
//  ViewController.swift
//  AudioUIKit Example
//
//  Created by Adam Ritenauer on 9/10/16.
//  Copyright © 2016 Adam Ritenauer. All rights reserved.
//

import UIKit
import WaveformView

class ViewController: UIViewController {

	@IBOutlet private weak var waveform:WaveformView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		waveform.url = NSBundle.mainBundle().URLForResource("demo", withExtension: "mp3")
		waveform.waveColor = UIColor.blueColor()
		waveform.pointsPerSecond = 100
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

