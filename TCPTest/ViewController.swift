//
//  ViewController.swift
//  TCPTest
//
//  Created by zhaobing on 2018/6/5.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
 
    var clientSocket:GCDAsyncSocket!
    //测试
    let hostip = "192.168.1.147"//"192.168.1.244"//"192.168.0.1"
    let port = "9999"//"9999"//"8266"
    
//    let hostip = "192.168.0.1"
//    let port = "8266"
    @IBOutlet weak var imgBtn1: UIButton!
    @IBOutlet weak var imgBtn2: UIButton!
    @IBOutlet weak var imgBtn3: UIButton!
    @IBOutlet weak var connectStatus: UILabel!
    @IBOutlet weak var testImageView: UIImageView!
    //private var cycyleTimer:Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        imgBtn1.imageView?.contentMode=UIViewContentMode.scaleAspectFit
        imgBtn2.imageView?.contentMode=UIViewContentMode.scaleAspectFit
        imgBtn3.imageView?.contentMode=UIViewContentMode.scaleAspectFit
        testImageView.contentMode=UIViewContentMode.scaleAspectFit
    }
    
//    @objc func repeatFunc() {//需要重复执行的调用
//        if curSendIndex<totalCount&&curSendIndex>0 {
//            let dateTime = Date().timeIntervalSince(starDate)
//            print(dateTime)
//
//        }
//    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clientSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        do {
            try clientSocket?.connect(toHost: hostip, onPort: UInt16(port)!)
        }catch _ {
            //addText(text: "连接产测系统成功")
        }
        
//        cycyleTimer = Timer(timeInterval: 2, target: self, selector: #selector(self.repeatFunc), userInfo: nil, repeats: true)
//        RunLoop.main.add(cycyleTimer!, forMode: RunLoopMode.commonModes)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    var curImgData = Data()
    let onceCount = 60000//每次发送长度，最后一次不一定
    var totalCount = 0
    var curSendIndex = 0
    //var starDate = Date()
    let timeOut = 10
    
    
    
    
    @IBAction func imgClick(_ sender: UIButton) {
        //curSendIndex = 0
        totalCount = 0
        //starDate=Date()
        SVProgressHUD.showProgress(0, status: "0%")
        let imgName = "img\(sender.tag+1).jpg"
        let tmpImage = UIImage.init(named: imgName)
        
        self.curImgData=(tmpImage?.getRGB656Data())!
        
        self.totalCount=Int(ceil(Double(self.curImgData.count)/Double(self.onceCount)))//发送次数
        let sendData = Data.init(bytes: [0x02,UInt8(self.totalCount),0x00,0x00,0x01,0x00])//命令1，发送总次数1
       
        self.sendDataToDevice(data: sendData)
        print("图片总长度\(self.curImgData.count)，总共发送次数\(self.totalCount)")
 
        testImageView.image=ImageRGBRGBHelper.image(fromRGB565: UnsafeMutableRawPointer(mutating: (curImgData as NSData).bytes) , width: Int32(Int((tmpImage?.size.width)!)), height: Int32(Int((tmpImage?.size.height)!)))
        
    }

    func getCrc8Data(inputData:Data) -> Data {
        var outData = inputData
        var crc8 = 0
        
        for item in inputData {
            crc8=(crc8+Int(item))%256
        }
        outData.append(UInt8(crc8))
        return outData
    }
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBAction func segmentClick(_ sender: UISegmentedControl) {//1,2,3
        print(sender.selectedSegmentIndex)
        let tmpData=Data.init(bytes: [0x01,0x00,0x00,0x00,0x01,UInt8(sender.selectedSegmentIndex+1)])
        sendDataToDevice(data: tmpData)
    }
    @IBOutlet weak var valueLabel: UILabel!
    
    //发送消息按钮事件
    func sendDataToDevice(data:Data) {
        //let txtData:Data = (msgTF.text?.data(using: String.Encoding.utf8))!
        var needData = Data.init(bytes: [0x82])
        needData.append(data)
        needData=getCrc8Data(inputData: needData)
        clientSocket.write(needData, withTimeout: -1, tag: 0)
        clientSocket.readData(withTimeout: -1, tag: 0)
    }
    
}
extension ViewController: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
    
        sock.readData(withTimeout: -1, tag: 0)
        DispatchQueue.main.async {
            self.connectStatus.text="当前连接状态：已连接成功"
        }
    }
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
   
        DispatchQueue.main.async {
            self.connectStatus.text="当前连接状态：已断开连接"
        }
        do {
            try clientSocket.connect(toHost: hostip, onPort: UInt16(port)!)
            
        }catch _ {
        }
        self.clientSocket.readData(withTimeout: -1, tag: 0)
        
    }
    
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        //print("收到数据:"+String(data: data, encoding: String.Encoding.utf8)!)
        if data[0]==0x26&&data.count>=2 {
            switch data[1] {
            case 0x01:
                let length = Int(data[4])*256+Int(data[5])
                var tmpValue:CLongLong = 0
                
                for i in 0..<length
                {
                    tmpValue+=CLongLong(data[6+i])*CLongLong(powf(156, Float(length-1-i)))
                }
                DispatchQueue.main.async {
                    self.valueLabel.text="\(tmpValue)"
                }
                
                break
            case 0x02://图片交互
                if data[6]==0xff{
                    print("图片传输完成")//100
                    //SVProgressHUD.dismiss()
                }
                SVProgressHUD.dismiss()
                break
            case 0x03://图片交互
                
                let reveTotal = Int(data[2])//收到的总长度
                if reveTotal != totalCount
                {
                    print("收到总包数据跟当前发送的不一致")
                    return
                }
                
                print("收到第\(Int(data[3]))包数据请求")
                let indexNumber = Int(data[3])
                DispatchQueue.main.async {
                    SVProgressHUD.showProgress(Float(indexNumber)/Float(self.totalCount), status: "\(100*Float(indexNumber)/Float(self.totalCount))%")
                }
                if indexNumber<totalCount{
                    var sendData = Data.init(bytes: [0x03,UInt8(reveTotal),UInt8(indexNumber),UInt8(onceCount/256),UInt8(onceCount%256)])
                    let tmpImgData = curImgData.subData(starIndex: (indexNumber-1)*onceCount, count: onceCount)
                    sendData.append(tmpImgData)
                    sendDataToDevice(data: sendData)
                    
                }else if indexNumber==totalCount{
                    let lastCount = curImgData.count%onceCount
                    var sendData = Data.init(bytes: [0x03,UInt8(reveTotal),UInt8(indexNumber),UInt8(lastCount/256),UInt8(lastCount%256)])
                    let tmpImgData = curImgData.subData(starIndex: (indexNumber-1)*onceCount, count: lastCount)
                    sendData.append(tmpImgData)
                    sendDataToDevice(data: sendData)
                    
                }
                break
            case 0x04://数据显示
                break
            case 0xFF:
                break
            case 0xFE:
                break
            case 0xFC:
                break
            default:
                break
            }
        }
        clientSocket?.readData(withTimeout: -1, tag: 0)
    }
    
    
    
}
