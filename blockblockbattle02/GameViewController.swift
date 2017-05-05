//
//  GameViewController.swift
//  blockblockbattle02
//
//  Created by Tomoyuki Hayakawa on 2017/04/24.
//  Copyright © 2017年 Tomoyuki Hayakawa. All rights reserved.
//

import UIKit
import CoreMotion
import MultipeerConnectivity


class GameViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate{
	
	@IBOutlet weak var p1pad: UIImageView!
	@IBOutlet weak var showBrowser: UIButton!
    
    @IBOutlet weak var blueBlockImage: UIImageView!
    @IBOutlet weak var yellowBlockImage: UIImageView!
    @IBOutlet weak var redBlockImage: UIImageView!
    @IBOutlet weak var greenBlockImage: UIImageView!
   
    
	
	// 加速度の宣言
	var playerMotionManager : CMMotionManager!
	// 自分の加速度
	var p1SpeedX : Double = 0.0
	// パッドの位置(X座標)
	var p1PosX : CGPoint!
	
	// multipeerConnectivity関連
	let serviceType = "LCOC-Chat"
	var browser : MCBrowserViewController!
	var assistant : MCAdvertiserAssistant!
	var session : MCSession!
	var peerID: MCPeerID!
	
	// ボールの速度
	var vecX : CGFloat = 7.0
	var vecY : CGFloat = -7.0
	
    var startTimer : Timer!
    
	// ボールイメージ
	@IBOutlet weak var ballImage: UIImageView!
	
	// 画面サイズの取得
	let screenSize = UIScreen.main.bounds.size
    
    // カウント秒
    var second : Int = 0
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
		// 非表示
		ballImage.isHidden = true
		
		// multipeerConnectivity関連
		self.peerID = MCPeerID(displayName: UIDevice.current.name)
		self.session = MCSession(peer: peerID)
		self.session.delegate = self
		
		// create the browser viewcontroller with a unique service name
		self.browser = MCBrowserViewController(serviceType:serviceType,
		                                       session:self.session)
		self.browser.delegate = self;
		self.assistant = MCAdvertiserAssistant(serviceType:serviceType,
		                                       discoveryInfo:nil, session:self.session)
		self.assistant.start()
		
		// 描画の更新
        
        
		Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(self.viewUpdate), userInfo: nil, repeats: true)
        
		// MotionManagerを生成
		playerMotionManager = CMMotionManager()
		playerMotionManager.accelerometerUpdateInterval = 0.02
		// 加速度による操作の開始
		
    }

	func barUpdate(speedX : Int, fromPeer peerID: MCPeerID) {
		
		switch peerID {
		case self.peerID:
			break
		default:
			break
        }
	}
	
	// 加速度を使ったバーの操作
	func startAccelerometer() {
		// 加速度を取得する
		let handler : CMAccelerometerHandler = {(CMAccelerometerData:CMAccelerometerData?, error:Error?) -> Void in
			self.p1SpeedX += CMAccelerometerData!.acceleration.x
			// プレイヤーの中心位置を設定
			var p1PosX = self.p1pad.center.x + (CGFloat(self.p1SpeedX) * 3.5)
			
			// padの位置を修正
			if p1PosX <= 0 + (self.p1pad.frame.width / 2) {
				self.p1SpeedX = 0
				p1PosX = 0 + (self.p1pad.frame.width / 2)
			}
			if p1PosX >= self.screenSize.width - (self.p1pad.frame.width / 2) {
				self.p1SpeedX = 0
				p1PosX = self.screenSize.width - (self.p1pad.frame.width / 2)
			}
			// 修正した位置を適用
			self.p1pad.center.x = p1PosX
		}
		// 加速度の開始
		playerMotionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: handler)
	}
	
	// 画面の更新
	func viewUpdate() {
		// ボール
		var posX = self.ballImage.center.x
		var posY = self.ballImage.center.y
		
		// ボールに速度の追加
		posX += vecX
		posY += vecY
		
		// 画面端の当たり判定
		if posX <= 0 {
			vecX = vecX * -1
		}
		if posX >= self.screenSize.width {
			vecX = vecX * -1
		}
        // ボールが画面上部へ行った時
		if posY <= 0 {
			
            // 相手へボールの座標の送信
            var ballPostion = self.ballImage.center
            let data = NSData(bytes: &ballPostion, length: MemoryLayout<CGPoint>.size)
            do {
                try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            } catch {
                print(error)
            }
            
            //ボールを見えなくする
            ballImage.isHidden = true
            
		}
		if posY >= self.screenSize.height {
			vecY = vecY * -1
		}
        
        // プレイヤー1のパッドの当たり判定
        if ballImage.frame.intersects(p1pad.frame) {
            // 上からボールが来た時
            let ballPosY = self.ballImage.frame.minY

            if ballPosY < self.p1pad.frame.minY {
                posY -= self.ballImage.frame.height/2
                vecY = vecY * -1
            } else if ballPosY > self.p1pad.frame.minY {
                posY += self.ballImage.frame.height/2
                vecY = vecY * -1
            }
        }
    
		// ボールの位置の適用
		self.ballImage.center = CGPoint(x: posX, y: posY)
		
	}
    
    func startCount() {
        print("timer start")
        showBrowser.isHidden = true
        second += 1
        if second >= 4 {
            startTimer.invalidate()
            gameStart()
        }
    }
	
	// ゲーム開始
	func gameStart() {
		
		ballImage.isHidden = false
		// ボールの最初の位置
		ballImage.center = CGPoint(x: screenSize.width/2, y: screenSize.height/2)
		// 加速度の取得と送信の開始
		startAccelerometer()
		
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func showBrowser(_ sender: Any) {
		self.present(self.browser, animated: true, completion: nil)
	}
	
	// 通信が完了してDoneボタンが押されたとき
	func browserViewControllerDidFinish(
		_ browserViewController: MCBrowserViewController)  {
		// Called when the browser view controller is dismissed (ie the Done
		// button was tapped)
        // ブラウザーボタンの非表示
		showBrowser.isHidden = true
        // 準備完了のパスワード
        var reday = 19193773
        let data = NSData(bytes: &reday, length: MemoryLayout<NSInteger>.size)
        
        // 相手へ送信
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        // タイマーの開始
        startTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.startCount), userInfo: nil, repeats: true)
        startTimer.fire()
		self.dismiss(animated: true, completion: nil)
	}
	
	func browserViewControllerWasCancelled(
		_ browserViewController: MCBrowserViewController)  {
		// Called when the browser view controller is cancelled
		
		self.dismiss(animated: true, completion: nil)
	}
	
	// 相手からNSDataが送られてきたとき
	func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID)  {
		DispatchQueue.main.async() {
			
            // 送られてきたデータ
            let data = NSData(data: data)
            var getData : NSInteger = 0
            var getPoint : CGPoint!
            
            // CGPointが送られてきたとき
            if (data.length == MemoryLayout<CGPoint>.size) {
                //var receivedPoint = UnsafePointer<CGPoint>(data.bytes).memory
                data.getBytes(&getPoint, length: data.length)
                print("\(getPoint.x), \(getPoint.y)")
            }
        
            // NSIntegerが送られてきたとき
            if data.length == MemoryLayout<NSInteger>.size {
                data.getBytes(&getData, length: data.length)
            }
            
            // 相手の準備が完了
            if getData == 19193773 {
                self.vecX = -7.0
                self.vecY = 7.0
                
                self.startTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.startCount), userInfo: nil, repeats: true)
                self.startTimer.fire()
            }
            
			// ボールの出現
			self.barUpdate(speedX: getData, fromPeer: peerID)
		}
	}
	
	// The following methods do nothing, but the MCSessionDelegate protocol
	// requires that we implement them.
	func session(_ session: MCSession,
	             didStartReceivingResourceWithName resourceName: String,
	             fromPeer peerID: MCPeerID, with progress: Progress)  {
		
		// Called when a peer starts sending a file to us
	}
	
	func session(_ session: MCSession,
	             didFinishReceivingResourceWithName resourceName: String,
	             fromPeer peerID: MCPeerID,
	             at localURL: URL, withError error: Error?)  {
		// Called when a file has finished transferring from another peer
	}
	
	func session(_ session: MCSession, didReceive stream: InputStream,
	             withName streamName: String, fromPeer peerID: MCPeerID)  {
		// Called when a peer establishes a stream with us
	}
	
	func session(_ session: MCSession, peer peerID: MCPeerID,
	             didChange state: MCSessionState)  {
		// Called when a connected peer changes state (for example, goes offline)
		
	}

}
