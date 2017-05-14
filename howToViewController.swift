//
//  howToViewController.swift
//  blockblockbattle02
//
//  Created by Tomoyuki Hayakawa on 2017/05/14.
//  Copyright © 2017年 Tomoyuki Hayakawa. All rights reserved.
//

import UIKit

class howToViewController: UIViewController {
    
    
    @IBOutlet weak var howToImage: UIImageView!

    let image01 = UIImage(named: "howToImage_01")
    let image02 = UIImage(named: "howToImage_02")
    let image03 = UIImage(named: "howToImage_03")
    let image04 = UIImage(named: "howToImage_04")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pageControl(sender: UIPageControl) {
        switch sender.currentPage {
        case 0:
            howToImage.image = image01
            break
        case 1:
            howToImage.image = image02
            break
        case 2:
            howToImage.image = image03
            break
        case 3:
            howToImage.image = image04
            break
        default:
            break
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
