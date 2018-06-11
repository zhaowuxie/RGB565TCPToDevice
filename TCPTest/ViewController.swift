//
//  ViewController.swift
//  TCPTest
//
//  Created by zhaobing on 2018/6/5.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

import UIKit

class ViewController: UIViewController,TZImagePickerControllerDelegate {
 
    var clientSocket:GCDAsyncSocket!
    //测试
//    let hostip = "192.168.1.147"//"192.168.1.244"//"192.168.0.1"
//    let port = "9999"//"9999"//"8266"
    
    let hostip = "192.168.0.1"
    let port = "8266"
    @IBOutlet weak var imgBtn1: UIButton!
    @IBOutlet weak var imgBtn2: UIButton!
    @IBOutlet weak var imgBtn3: UIButton!
    @IBOutlet weak var connectStatus: UILabel!
    @IBOutlet weak var testImageView: UIImageView!
    //private var cycyleTimer:Timer?
    @IBOutlet weak var alertLabel: UILabel!
    @IBAction func AddImageClick(_ sender: Any) {//选择图片点击事件
        let imagePickerVc = TZImagePickerController.init(maxImagesCount: 1, delegate: self)
        imagePickerVc?.allowPickingVideo=false
        imagePickerVc?.allowPickingMultipleVideo=false
        imagePickerVc?.allowPickingOriginalPhoto=false
        imagePickerVc?.allowPickingGif=false
        imagePickerVc?.allowPickingGif=true
        imagePickerVc?.allowCrop=true
        // 设置竖屏下的裁剪尺寸
        let tmpwidth = CGFloat(self.view.frame.width-40)
        let tmpheight = tmpwidth*CGFloat(320.0/240)
        let left = (self.view.frame.width - tmpwidth)/2;
        let top = (self.view.frame.height - tmpheight) / 2;
        imagePickerVc?.cropRect = CGRect.init(x: left, y: top, width: tmpwidth, height: tmpheight)
        // You can get the photos by block, the same as by delegate.
        // 你可以通过block或者代理，来得到用户选择的照片.
        imagePickerVc?.didFinishPickingPhotosHandle={(photos:[UIImage]?,assets:[Any]?,tt:Bool)->Void  in
            if (photos?.count)!>0 {
                //let tmpdata=UIImageJPEGRepresentation((photos?[0])!, 120/tmpwidth)
                let tmpImg = self.SetImgSize(oldImg: (photos?[0])!)//改变尺寸
                self.testImageView.image=tmpImg
                self.StarSendImg(tmpImage: tmpImg)
            }
        }
        self.present(imagePickerVc!, animated: !true, completion: nil)
       
    }
    func SetImgSize(oldImg:UIImage) -> UIImage {
        // 创建一个bitmap的context
        let newSize = CGSize.init(width: 240, height: 320)
        
        UIGraphicsBeginImageContext(newSize);
        // 绘制改变大小的图片
        oldImg.draw(in: CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height))
        //[oldImg drawInRect:CGRectMake(0, 0, Newsize.width, Newsize.height)];
        // 从当前context中创建一个改变大小后的图片
        let TransformedImg=UIGraphicsGetImageFromCurrentImageContext();
        // 使当前的context出堆栈
        UIGraphicsEndImageContext();
        // 返回新的改变大小后的图片
        return TransformedImg!
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        imgBtn1.imageView?.contentMode=UIViewContentMode.scaleAspectFit
        imgBtn2.imageView?.contentMode=UIViewContentMode.scaleAspectFit
        imgBtn3.imageView?.contentMode=UIViewContentMode.scaleAspectFit
        testImageView.contentMode=UIViewContentMode.scaleAspectFit
        
        // app从后台进入前台都会调用这个方法
        NotificationCenter.default.addObserver(self, selector: #selector(applicationBecomeActive), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        // 添加检测app进入后台的观察者
        NotificationCenter.default.addObserver(self, selector: #selector(applicationEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    
    }
    @objc func applicationBecomeActive()  {
        initSSidAndSocket()
    }
    @objc func applicationEnterBackground()  {
        let sendData = Data.init(bytes: [0xfc])//断开链接
        self.sendDataToDevice(data: sendData)
    }
//    @objc func repeatFunc() {//需要重复执行的调用
//        if curSendIndex<totalCount&&curSendIndex>0 {
//            let dateTime = Date().timeIntervalSince(starDate)
//            print(dateTime)
//
//        }
//    }
    func initSSidAndSocket() {
        if let ssid=ImageRGBRGBHelper.fetchSSIDInfo()
        {
            print(ssid)
            if ssid.lowercased().contains("LCD demo-".lowercased())
            {
                alertLabel.text="提示：当前连接Wi-Fi为："+ssid
            }else{
                alertLabel.text="提示：当前wifi（"+ssid+"）不正确，请到手机  设置->无线局域网 ，选择连接wifi名为”LCD demo-xxxx“网络，然后方可进行下面测试！"
            }
            
        }else{
            alertLabel.text="提示：当前未连接wifi，请到手机  设置->无线局域网 ，选择连接wifi名为”LCD demo-xxxx“网络，然后方可进行下面测试！"
        }
        
        clientSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        do {
            try clientSocket?.connect(toHost: hostip, onPort: UInt16(port)!)
        }catch _ {
            
            
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initSSidAndSocket()
        
//        cycyleTimer = Timer(timeInterval: 2, target: self, selector: #selector(self.repeatFunc), userInfo: nil, repeats: true)
//        RunLoop.main.add(cycyleTimer!, forMode: RunLoopMode.commonModes)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let sendData = Data.init(bytes: [0xfc])//断开链接
        self.sendDataToDevice(data: sendData)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    var curImgData = Data()
    var onceCount = 60000//每次发送长度，最后一次不一定
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
        
        StarSendImg(tmpImage: tmpImage!)
        
    }

    func StarSendImg(tmpImage:UIImage) {
        self.curImgData=(tmpImage.getRGB656Data())
        self.onceCount=self.curImgData.count
        self.totalCount=Int(ceil(Double(self.curImgData.count)/Double(self.onceCount)))//发送次数
        
        let sendData = Data.init(bytes: [0x02,UInt8(self.totalCount),0x01,0x01,0x00,0x00,0x01,0x00])//命令1，发送总次数1
        
        self.sendDataToDevice(data: sendData)
        print("图片总长度\(self.curImgData.count)，总共发送次数\(self.totalCount)")
        
        testImageView.image=ImageRGBRGBHelper.image(fromRGB565: UnsafeMutableRawPointer(mutating: (curImgData as NSData).bytes) , width: Int32(Int((tmpImage.size.width))), height: Int32(Int((tmpImage.size.height))))
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
        let tmpData=Data.init(bytes: [0x01,0x01,0x01,0x00,0x00,0x00,0x01,UInt8(sender.selectedSegmentIndex+1)])
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
                let length = Int(data[4])*256*256*256+Int(data[5])*256*256+Int(data[6])*256+Int(data[7])
                var tmpValue:CLongLong = 0
                
                for i in 0..<length
                {
                    tmpValue+=CLongLong(data[8+i])*CLongLong(powf(156, Float(length-1-i)))
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
                var sendCount = onceCount
                
                if indexNumber==totalCount{
                    let lastCount = curImgData.count%onceCount
                    sendCount=(lastCount==0 ? onceCount:lastCount)
                }
                let len4 = Int(sendCount%256)
                let len3 = Int((sendCount>>8)%256)
                let len2 = Int((sendCount>>16)%256)
                let len1 = Int((sendCount>>24)%256)
                var sendData = Data.init(bytes: [0x03,UInt8(reveTotal),UInt8(indexNumber),UInt8(len1),UInt8(len2),UInt8(len3),UInt8(len4)])
                
                let tmpImgData = curImgData.subData(starIndex: (indexNumber-1)*onceCount, count: sendCount)
                sendData.append(tmpImgData)
                sendDataToDevice(data: sendData)
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
