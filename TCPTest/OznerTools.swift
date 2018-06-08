//
//  OznerTools.swift
//  OznerLibrarySwiftyDemo
//
//  Created by 赵兵 on 2017/1/5.
//  Copyright © 2017年 net.ozner. All rights reserved.
//

import UIKit
struct OznerDeviceInfo {
    var deviceID = ""//设备唯一ID
    var deviceMac = ""//设备Mac：访问服务器和接口的时候才用到这个，或者Wi-Fi协议里面会用这个，其余的都用deviceID
    var deviceType = ""
    /*
     productID
     蓝牙产品为"BLUE"
     wifi产品为 a.2.0水机 "737bc5a2-f345-11e6-9d95-00163e103941"
     b.1.0水机 MXCHIP_HAOZE_Water
     c.1.0空净 FOG_HAOZE_AIR
     */
    var productID = ""
    var wifiVersion = 1//wifi版本，1或2
    
    
    func des() -> String {
        return "设备ID:\(self.deviceID)\n设备Mac:\(self.deviceMac)\n设备型号:\(self.deviceType)\n产品ID:\(self.productID)\nWiFi版本:\(self.wifiVersion)"
    }
}
class OznerTools: NSObject {
    
    class func dataFromInt16(number:UInt16)->Data {
        
        let data = NSMutableData()
        //        var val = CFSwapInt16HostToBig(number)
        var val = CFSwapInt16LittleToHost(number)
        
        data.append(&val, length: MemoryLayout<UInt16>.size)
        
        return data as Data
    }
    
    class func dataFromInt(number:CLongLong,length:Int)->Data{
        var data=Data()
        if length<1 {
            return data
        }
        var tmpValue = CLongLong(0)
        for i in 0...(length-1) {
            let powInt = CLongLong(pow(CGFloat(256), CGFloat(i)))
            let needEle=(number-tmpValue)/powInt%256
            data.append(UInt8(needEle))
            tmpValue+=CLongLong(needEle)*powInt
        }
        return data
    }
    
    class func hexStringFromData(data:Data)->String{
        var hexStr=""
        for i in 0..<data.count {
            if Int(data[i])<16 {
                hexStr=hexStr.appendingFormat("0")
            }
            hexStr=hexStr.appendingFormat("%x",Int(data[i]))
        }
        return hexStr
    }
    
    class func hexStringToData(strHex:String)->Data{
        var data=Data()
        if strHex.characters.count%2 != 0 {
            return data
        }
        for i in 0..<strHex.characters.count/2 {
            let range1 = strHex.index(strHex.startIndex, offsetBy: i*2)
            let range2 = strHex.index(strHex.startIndex, offsetBy: i*2+2)
            let hexString = strHex.substring(with: Range(range1..<range2))
            var result1:UInt32 = 0
            Scanner(string: hexString).scanHexInt32(&result1)
            data.insert(UInt8(result1), at: i)
        }
        return data
    }
    
    //    class func publicString(payload:Data,deviceid:String,callback:((Int32)->Void)!){
    //        let payloadStr=OznerTools.hexStringFromData(data: payload)
    //        let params = ["username" : "bing.zhao@cftcn.com","password" : "l5201314","deviceid" : deviceid,"payload" : payloadStr]//设置参数
    //        //print("2.0发送指令："+payloadStr)
    //        Helper.post("https://v2.fogcloud.io/enduser/sendCommandHz/", requestParams: params) { (response, data, error) in
    //            print(error ?? "")
    //        }
    //
    //    }
    
    
}
extension Data{
    
    func subInt(starIndex:Int,count:Int) -> Int {
        if starIndex+count>self.count {
            return 0
        }
        var dataValue = 0
        for i in 0..<count {
            dataValue+=Int(Float(self[i+starIndex])*powf(256, Float(i)))
        }
        return dataValue
    }
    
    func subString(starIndex:Int,count:Int) -> String {
        if starIndex+count>self.count {
            return ""
        }
        let range1 = self.index(self.startIndex, offsetBy: starIndex)
        let range2 = self.index(self.startIndex, offsetBy: starIndex+count)
        let valueData=self.subdata(in: Range(range1..<range2))
        return String.init(data: valueData, encoding: String.Encoding.utf8)!
    }
    
    func subData(starIndex:Int,count:Int) -> Data {
        if starIndex+count>self.count {
            return Data.init()
        }
        let range1 = self.index(self.startIndex, offsetBy: starIndex)
        let range2 = self.index(self.startIndex, offsetBy: starIndex+count)
        return self.subdata(in: Range(range1..<range2))
    }
}
extension UIImage{
    func getRGB656Data()->Data{
        var RGBData = Data()
        
        ImageRGBRGBHelper.getRGBData(from: self) { (r,g,b) in
            let r1 = UInt16(r>>3)
            let g1 = UInt16(g>>2)
            let b1 = UInt16(b>>3)
            let tmpValue=UInt16(r1<<11+g1<<5+b1)
            let HgightUint8 = (tmpValue&0xff00)>>8
            let lowUint8 = tmpValue&0x00ff
            RGBData.append(contentsOf: [UInt8(lowUint8),UInt8(HgightUint8)])
            
        }
        return RGBData
    }
    
}



