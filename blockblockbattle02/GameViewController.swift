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
	@IBOutlet weak var p2pad: UIImageView!
	
	@IBOutlet weak var showBrowser: UIButton!
	
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
	
	// ボールイメージ
	@IBOutlet weak var ballImage: UIImageView!
	
	// 画面サイズの取得
	let screenSize = UIScreen.main.bounds.size
	
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
			// 送られて来た値を扱えるように変換
			let box : Double = Double(speedX)
			var p2SpeedX : Double = box / 100000000000.0
			//print("送られてきた値 : \(p2SpeedX)")
			
			// padの操作
			var p2PosX = self.p2pad.center.x - (CGFloat(p2SpeedX) * 3.5)
			// padの位置を修正
			if p2PosX <= 0 + (self.p2pad.frame.width / 2) {
				p2SpeedX = 0
				p2PosX = 0 + (self.p2pad.frame.width / 2)
			}
			if p2PosX >= self.screenSize.width - (self.p2pad.frame.width / 2) {
				p2SpeedX = 0
				p2PosX = self.screenSize.width - (self.p2pad.frame.width / 2)
			}
			// 修正した位置を適用
			self.p2pad.center.x = p2PosX
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
			// 相手に加速度の送信
			let some : Double = self.p1SpeedX * 100000000000.0
			var sendSpeedX : Int = Int(some)
			print(sendSpeedX)
			let data = NSData(bytes: &sendSpeedX, length: MemoryLayout<NSInteger>.size)
			// 相手へ送信
			do {
				try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
			} catch {
				print(error)
			}
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
		if posY <= 0 {
			vecY = vecY * -1
		}
		if posY >= self.screenSize.height {
			vecY = vecY * -1
		}
		
		if abs(ballImage.center.y - p1pad.center.y) <= ballImage.frame.height/2 + p1pad.frame.height/2 && abs(ballImage.center.x - p1pad.center.x) <= ballImage.frame.width/2 + p1pad.frame.width/2 {
			// ボールが上面に衝突した場合
			if posY < p1pad.center.y {
				vecY = vecY * -1
				self.ballImage.center = CGPoint(x: posX, y: posY+ballImage.frame.height/2)
			}
			// ボールが下面に衝突した場合
//			if posY > p1pad.center.y {
//				vecY = vecY * -1
//				self.ballImage.center = CGPoint(x: posX, y: posY)
//			}
		}
//		if ballImage.frame.intersects(p2pad.frame) {
//			// ボールが上面に衝突した場合
//			if posY <= p2pad.center.y {
//				vecY = vecY * -1
//			}
//			// ボールが下面に衝突した場合
//			if posY >= p2pad.center.y {
//				vecY = vecY * -1
//			}
//		}
		// ボールの位置の適用
		self.ballImage.center = CGPoint(x: posX, y: posY)
		
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
		showBrowser.isHidden = true
		gameStart()
		viewUpdate()
		self.dismiss(animated: true, completion: nil)
	}
	
	func browserViewControllerWasCancelled(
		_ browserViewController: MCBrowserViewController)  {
		// Called when the browser view controller is cancelled
		
		self.dismiss(animated: true, completion: nil)
	}
	
	// 相手からNSDataが送られてきたとき
	func session(_ session: MCSession, didReceive data: Data,
	             fromPeer peerID: MCPeerID)  {
		DispatchQueue.main.async() {
			let data = NSData(data: data)
			var p2SpeedX : NSInteger = 0
			data.getBytes(&p2SpeedX, length: data.length)
			// ラベルの更新
			self.barUpdate(speedX: p2SpeedX, fromPeer: peerID)
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
