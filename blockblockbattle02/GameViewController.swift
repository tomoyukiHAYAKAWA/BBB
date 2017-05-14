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
    
    @IBOutlet weak var backBtn: UIButton!
        
    @IBOutlet weak var blueBlockImage: UIImageView!
    @IBOutlet weak var yellowBlockImage: UIImageView!
    @IBOutlet weak var redBlockImage: UIImageView!
    @IBOutlet weak var greenBlockImage: UIImageView!
    
    @IBOutlet weak var p2blueBlockImage: UIImageView!
    @IBOutlet weak var p2yellowBlockImage: UIImageView!
    @IBOutlet weak var p2redBlockImage: UIImageView!
    @IBOutlet weak var p2greenBlockImage: UIImageView!
    
    @IBOutlet weak var countImage: UIImageView!
    
    @IBOutlet weak var topImage: UIImageView!
    
	// 加速度の宣言
	var playerMotionManager : CMMotionManager!
	// 自分の加速度
	var p1SpeedX : Double = 0.0
	// パッドの位置(X座標)
	var p1PosX : CGPoint!
    
    // 送られてきたボールの位置
    var firstBallPosX : CGFloat!
	
	// multipeerConnectivity関連
	let serviceType = "LCOC-Chat"
	var browser : MCBrowserViewController!
	var assistant : MCAdvertiserAssistant!
	var session : MCSession!
	var peerID: MCPeerID!
	
	// ボールの速度
	var vecX : CGFloat = 8
	var vecY : CGFloat = -8
    
    
    // 開始のタイマー
    var startTimer : Timer!
    
    // ビューのアップデートタイマー
    var viewUpdateTimer : Timer!
    
	// ボールイメージ
	@IBOutlet weak var ballImage: UIImageView!
	
	// 画面サイズの取得
	let screenSize = UIScreen.main.bounds.size
    var screenTop : CGFloat!
    
    // カウント秒
    var second : Int = 5
    
    // プレイヤー1ライフ
    var player1Life : Int = 4
    // プレイヤー2ライフ
    var player2Life : Int = 4
    
    // プレイヤー1フラッグ
    var player1Flag : Bool = false
    
    // 送信フラッグ
    var sendBallFlag : Bool = false
    var sendVecFlag : Bool = false
    
    // 戦績用変数
//    var win : Int!
//    var lose : Int!
//    var dBlock : Int!
//    var bBlock : Int!
//    var ballBlock : Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
		// 非表示
		ballImage.isHidden = true
        countImage.isHidden = true
		
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
        
		// MotionManagerを生成
		playerMotionManager = CMMotionManager()
		playerMotionManager.accelerometerUpdateInterval = 0.02
		
        screenTop = topImage.frame.maxY
        
    }
    
    // 送られてきたベクトルの向き
    func vecUpdate(getVecX : Int) {
        if getVecX == -8 {
            vecX = 8
            vecY = 8
        } else if getVecX == 8 {
            vecX = -8
            vecY = 8
        }
    }

    // 送られてきたボールの位置
    func ballUpdate(postionX : Int, fromPeer peerID: MCPeerID) {
		
		switch peerID {
		// 自分の時
        case self.peerID:
			break
            
        // 相手の時
		default:
            
            let box = CGFloat(postionX)
            sendBallFlag = false
            sendVecFlag = false
            firstBallPosX = box/10000.0
    
            // 送られてきた座標にボールを適用
            self.ballImage.center.x = abs(firstBallPosX-screenSize.width)
            self.ballImage.center.y = screenTop
    
            // ボールの表示
            ballImage.isHidden = false
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
		if posY <= screenTop {
			
            if sendBallFlag == false && sendVecFlag == false {
                //print("screenTop:\(screenTop)")
                //print("posX:\(posY)")
                sendBallFlag = true
                sendVecFlag = true
                self.sendBallData()
                // ボールの位置を固定
                posX = self.ballImage.center.x
                posY = 0.0
            }
            
		}
		if posY >= self.screenSize.height {
			vecY = vecY * -1
		}
        
        // プレイヤー1のパッドの当たり判定
        if ballImage.frame.intersects(p1pad.frame) {
            // 上からボールが来た時
            let ballPosY = self.ballImage.frame.minY
            let ballPosX = self.ballImage.frame.minX

            if self.p1pad.frame.minX < ballPosX &&  ballPosX < self.p1pad.frame.maxX && ballPosY < self.p1pad.frame.minY {
                posY -= self.ballImage.frame.height/2
                vecY = vecY * -1
            // 下からボールが来たとき
            } else if self.p1pad.frame.minX < ballPosX &&  ballPosX < self.p1pad.frame.maxX && ballPosY > self.p1pad.frame.minY {
                posY += self.ballImage.frame.height/2
                vecY = vecY * -1
            // 右からボールが来たとき
            } else if self.p1pad.frame.minY < ballPosY && ballPosY < self.p1pad.frame.maxY && self.p1pad.frame.minX > ballPosX {
                posX -= self.ballImage.frame.width/2
                vecX = vecX * -1
            // 左からボールが来たとき
            } else if self.p1pad.frame.minY < ballPosY && ballPosY < self.p1pad.frame.maxY && self.p1pad.frame.minX < ballPosX {
                posX += self.ballImage.frame.width/2
                vecX = vecX * -1
            }
            
        }
        
        // バー青との当たり判定
        if ballImage.frame.intersects(blueBlockImage.frame) {

            // 相手へ残機の送信
            //self.sendLife()
            
            let ballPosY = self.ballImage.frame.minY
            let ballPosX = self.ballImage.frame.minX
            
            // ボールが上から来た時
            if ballPosY < self.blueBlockImage.frame.minY {
                posY -= self.ballImage.frame.height/2
                vecY = vecY * -1
                // ボールが下から来た時
            } else if ballPosY > self.blueBlockImage.frame.minY {
                posY += self.ballImage.frame.height/2
                vecY = vecY * -1
            } else if self.blueBlockImage.frame.minY < ballPosY && ballPosY < self.blueBlockImage.frame.maxY && self.blueBlockImage.frame.minX > ballPosX {
                posX -= self.ballImage.frame.width/2
                vecX = vecX * -1
            } else if self.blueBlockImage.frame.minY < ballPosY && ballPosY < self.blueBlockImage.frame.maxY && self.blueBlockImage.frame.minX < ballPosX {
                posX += self.ballImage.frame.width/2
                vecX = vecX * -1
            }
            
            // ブロックを消す
            blueBlockImage.isHidden = true
            blueBlockImage.center = CGPoint(x: blueBlockImage.center.x, y: 2000)
            
            var life = 12121212
            let data = NSData(bytes: &life, length: MemoryLayout<NSInteger>.size)
            // 相手へ送信
            do {
                try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            } catch {
                print(error)
            }
            
            
            player1Life -= 1
            // ライフが0になった時
            if player1Life == 0 {
                self.viewUpdateTimer.invalidate()
            }

        }
        
        // バー黄色との当たり判定
        if ballImage.frame.intersects(yellowBlockImage.frame) {
            //self.sendLife()
            
            let ballPosY = self.ballImage.frame.minY
            let ballPosX = self.ballImage.frame.minX
            
            // ボールが上から来た時
            if ballPosY < self.yellowBlockImage.frame.minY {
                posY -= self.ballImage.frame.height/2
                vecY = vecY * -1
                // ボールが下から来た時
            } else if ballPosY > self.yellowBlockImage.frame.minY {
                posY += self.ballImage.frame.height/2
                vecY = vecY * -1
            } else if self.yellowBlockImage.frame.minY < ballPosY && ballPosY < self.yellowBlockImage.frame.maxY && self.yellowBlockImage.frame.minX > ballPosX {
                posX -= self.ballImage.frame.width/2
                vecX = vecX * -1
            } else if self.yellowBlockImage.frame.minY < ballPosY && ballPosY < self.yellowBlockImage.frame.maxY && self.yellowBlockImage.frame.minX < ballPosX {
                posX += self.ballImage.frame.width/2
                vecX = vecX * -1
            }
            
            yellowBlockImage.isHidden = true
            yellowBlockImage.center = CGPoint(x: yellowBlockImage.center.x, y: 2000)
            
            var life = 21212121
            let data = NSData(bytes: &life, length: MemoryLayout<NSInteger>.size)
            // 相手へ送信
            do {
                try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            } catch {
                print(error)
            }
            
            player1Life -= 1
            // ライフが0になった時
            if player1Life == 0 {
                self.viewUpdateTimer.invalidate()
            }
            
        }
        
        // バー赤との当たり判定
        if ballImage.frame.intersects(redBlockImage.frame) {
            
            //self.sendLife()
            
            let ballPosY = self.ballImage.frame.minY
            let ballPosX = self.ballImage.frame.minX
            
            // ボールが上から来た時
            if ballPosY < self.redBlockImage.frame.minY {
                posY -= self.ballImage.frame.height/2
                vecY = vecY * -1
                // ボールが下から来た時
            } else if ballPosY > self.redBlockImage.frame.minY {
                posY += self.ballImage.frame.height/2
                vecY = vecY * -1
            } else if self.redBlockImage.frame.minY < ballPosY && ballPosY < self.redBlockImage.frame.maxY && self.redBlockImage.frame.minX > ballPosX {
                posX -= self.ballImage.frame.width/2
                vecX = vecX * -1
            } else if self.redBlockImage.frame.minY < ballPosY && ballPosY < self.redBlockImage.frame.maxY && self.redBlockImage.frame.minX < ballPosX {
                posX += self.ballImage.frame.width/2
                vecX = vecX * -1
            }
            
            redBlockImage.isHidden = true
            redBlockImage.center = CGPoint(x: redBlockImage.center.x, y: 2000)
            
            var life = 31313131
            let data = NSData(bytes: &life, length: MemoryLayout<NSInteger>.size)
            // 相手へ送信
            do {
                try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            } catch {
                print(error)
            }
            
            player1Life -= 1
            // ライフが0になった時
            if player1Life == 0 {
                self.viewUpdateTimer.invalidate()
            }
            
        }
        
        // バー緑との当たり判定
        if ballImage.frame.intersects(greenBlockImage.frame) {
            
            //self.sendLife()
            
            let ballPosY = self.ballImage.frame.minY
            let ballPosX = self.ballImage.frame.minX
            
            // ボールが上から来た時
            if ballPosY < self.greenBlockImage.frame.minY {
                posY -= self.ballImage.frame.height/2
                vecY = vecY * -1
                // ボールが下から来た時
            } else if ballPosY > self.greenBlockImage.frame.minY {
                posY += self.ballImage.frame.height/2
                vecY = vecY * -1
            } else if self.greenBlockImage.frame.minY < ballPosY && ballPosY < self.greenBlockImage.frame.maxY && self.greenBlockImage.frame.minX > ballPosX {
                posX -= self.ballImage.frame.width/2
                vecX = vecX * -1
            } else if self.greenBlockImage.frame.minY < ballPosY && ballPosY < self.greenBlockImage.frame.maxY && self.greenBlockImage.frame.minX < ballPosX {
                posX += self.ballImage.frame.width/2
                vecX = vecX * -1
            }
            
            greenBlockImage.isHidden = true
            greenBlockImage.center = CGPoint(x: greenBlockImage.center.x, y: 2000)
            
            var life = 41414141
            let data = NSData(bytes: &life, length: MemoryLayout<NSInteger>.size)
            // 相手へ送信
            do {
                try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            } catch {
                print(error)
            }
        
            player1Life -= 1
            // ライフが0になった時
            if player1Life == 0 {
                self.viewUpdateTimer.invalidate()
            }

            
        }
        
		// ボールの位置の適用
		self.ballImage.center = CGPoint(x: posX, y: posY)
		
	}
    
//    // 残機の送信
//    func sendLife() {
//        // 残機のパス
//        var life = 0
//        let data = NSData(bytes: &life, length: MemoryLayout<NSInteger>.size)
//        // 相手へ送信
//        do {
//            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
//        } catch {
//            print(error)
//        }
//    }
    
    // ボールの位置、ベクトルの送信
    func sendBallData() {
        // 相手へボールの座標の送信
        var ballPostion = self.ballImage.center.x
        ballPostion = ballPostion * 10000
        var sendBallPostionX : Int = Int(ballPostion)
        var data = NSData(bytes: &sendBallPostionX, length: MemoryLayout<NSInteger>.size)
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        // 相手へボールのベクトルの送信
        var sendVecX = Int(vecX)
        data = NSData(bytes: &sendVecX, length: MemoryLayout<NSInteger>.size)
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        // ボールを見えなくする
        ballImage.isHidden = true
    }
    
    // ゲーム開始のカウントダウン
    func startCount() {
        print("timer start")
        showBrowser.isHidden = true
        backBtn.isHidden = true
        countImage.isHidden = false
        switch second {
        case 5:
            let count3 = UIImage(named:"3")
            countImage.image = count3
            break
            
        case 4:
            let count2 = UIImage(named:"2")
            countImage.image = count2
            break

        case 3:
            let count1 = UIImage(named:"1")
            countImage.image = count1
            break
            
        case 2:
            let countgo = UIImage(named:"go")
            countImage.image = countgo
            break
            
        case 1:
            gameStart()
            countImage.isHidden = true
            startTimer.invalidate()
            break
        default:
            break
        }
        second -= 1
    }
	
	// ゲーム開始
	func gameStart() {
        // プレイヤー1からボールがスタート
        if player1Flag == true {
            ballImage.isHidden = false
        } else {
            ballImage.isHidden = true
        }
		// ボールの最初の位置
		ballImage.center = CGPoint(x: screenSize.width/2, y: screenSize.height/2)
        viewUpdateTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(self.viewUpdate), userInfo: nil, repeats: true)

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
        
        // 自分が対戦を申し込んだ側(player1)
        player1Flag = true
        
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
        
            // NSIntegerが送られてきたとき
            if data.length == MemoryLayout<NSInteger>.size {
                data.getBytes(&getData, length: data.length)
            }
            
            print(getData)
                
            switch getData {
                
            case -8 :
                self.vecUpdate(getVecX: getData)
                break
                
            case 8 :
                self.vecUpdate(getVecX: getData)
                break
                
            case 19193773 :
                self.startTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.startCount), userInfo: nil, repeats: true)
                self.startTimer.fire()
                break
                
            case 12121212 :
                print("block 青")
                self.player2Life -= 1
                self.p2blueBlockImage.isHidden = true
                if self.player2Life == 0 {
                    self.viewUpdateTimer.invalidate()
                }
                break
                    
            case 21212121 :
                print("block 黄色")
                self.player2Life -= 1
                self.p2yellowBlockImage.isHidden = true
                if self.player2Life == 0 {
                    self.viewUpdateTimer.invalidate()
                }
                break
                
            case 31313131 :
                print("block 赤")
                self.player2Life -= 1
                self.p2redBlockImage.isHidden = true
                if self.player2Life == 0 {
                    self.viewUpdateTimer.invalidate()
                }
            
                break
                
            case 41414141 :
                print("block 緑")
                self.player2Life -= 1
                self.p2greenBlockImage.isHidden = true
                if self.player2Life == 0 {
                    self.viewUpdateTimer.invalidate()
                }
                break
                
            default :
                // ボールの出現
                self.ballUpdate(postionX: getData, fromPeer: peerID)
                break
            }
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
