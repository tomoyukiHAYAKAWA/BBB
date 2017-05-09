//
//  ViewController.swift
//  blockblockbattle02
//
//  Created by Tomoyuki Hayakawa on 2017/04/23.
//  Copyright © 2017年 Tomoyuki Hayakawa. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var howToImage: UIImageView!
    

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
        
        howToImage.isHidden = true
        
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
    
    @IBAction func onBtn(_ sender: Any) {
        howToImage.isHidden = false
    }
    
    @IBAction func offBtn(_ sender: Any) {
        howToImage.isHidden = true
    }
    

}

